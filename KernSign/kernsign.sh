#!/usr/bin/env bash

function usage {
        echo "Sign mainline Linux kernel images."
        echo "Usage: $(basename "$0") [-p] -hlgedsa"
        echo "   -h            Display usage"
        echo "   -l            List installed kernels"
        echo "  [-p]           Preserve unsigned kernel"
        echo "   -g            Generate certificates"
        echo "   -e            Enroll certificates in MOK"
        echo "   -d            Delete certificates from MOK"
        echo "   -s [version]  Sign kernel. Latest kernel wil be signed if no [version] specified"
        echo "   -a [version]  Generate certificates, enroll in MOK and sign specified version"
        echo "                 (equivalent to $(basename "$0") -g -e -s [version] )"
        exit 1
}

function sign_kernel(){
    check_if_sudo
    check_sbsign

    # If no kernel-version is supplied, sign the latest (if not signed...)
    if [ ! "$KERNEL_VERSION" ]
    then
        printlog "No kernel version specified, signing latest."
        for filename in /boot/vmlinuz-*-generic
        do
            filename=${filename#*-}
            KERNEL_VERSION="${filename%-*}"
        done
            printlog "Kernel to be signed: vmlinuz-$KERNEL_VERSION-generic"
    fi

    if [ -e "/boot/vmlinuz-$KERNEL_VERSION-generic" ]
    then
        if [ -s "./MOK.priv" ] && [ -s "./MOK.pem" ] && [ -s "./MOK.der" ] 
        then
            # Are the available certificates valid 
            IS_VALID="$(openssl x509 -inform der -in ./MOK.der -outform pem | openssl verify -CAfile ./MOK.pem)"
            echo "$IS_VALID" >> log.txt
            if ! { [ "$IS_VALID" == "stdin: OK" ] ; }
            then
                printlog "Available certificates are not valid!"
                exit
            fi

            # Are the available certificates enrolled in MOK?
            IS_ENROLLED="$(mokutil --test-key MOK.der)"
            echo "$IS_ENROLLED" >> log.txt
            if ! { [[ "$IS_ENROLLED" == *"is already enrolled" ]] ; }
            then
                printlog "Available certificates are not enrolled in MOK."
                printlog "Enroll now? (y/N)"
                read -r INPUT
                echo "$INPUT" >> log.txt
                if ! { [ "$INPUT" == "y" ] || [ "$INPUT" == "Y" ]; }
                then
                    SB_ENABLED=$(mokutil --sb-state)
                    echo "$SB_ENABLED" >> log.txt
                    if [ "$SB_ENABLED" == "SecureBoot enabled" ]
                    then
                        printlog "SecureBoot is enabled. You WILL NOT be able to boot with the signed kernel!"
                        exit
                    else
                        printlog "SecureBoot is not enabled. If enabled, you WILL NOT be able to boot with the signed kernel!"
                    fi
                else
                    enroll_mok
                fi
            fi

            # Don't sign the kernel if it's already signed
            IS_SIGNED=$(sbverify --cert MOK.pem /boot/vmlinuz-"$KERNEL_VERSION"-generic) >> log.txt 2>&1
            echo "$IS_SIGNED" >> log.txt
            if [ "$IS_SIGNED" == "Signature verification OK" ]
            then
                printlog "Kernel is already signed!"
                exit
            else
                printlog "Kernel vmlinuz-$KERNEL_VERSION-generic is unsigned or may be signed with an unavailable key."
                printlog "Proceed? (y/N)"
                read -r INPUT
                echo "$INPUT" >> log.txt
                if ! { [ "$INPUT" == "y" ] || [ "$INPUT" == "Y" ]; }
                then
                    exit
                fi
            fi

            # Sign the kernel
            echo "signing kernel '/boot/vmlinuz-$KERNEL_VERSION-generic'..."
            sbsign --key MOK.priv --cert MOK.pem /boot/vmlinuz-"$KERNEL_VERSION"-generic --output /boot/vmlinuz-"$KERNEL_VERSION"-generic.signed >> log.txt 2>&1
            
            # Verify signature
            IS_SIGNED=$(sbverify --cert MOK.pem /boot/vmlinuz-"$KERNEL_VERSION"-generic.signed)
            echo "$IS_SIGNED" >> log.txt
            if [ "$IS_SIGNED" == "Signature verification OK" ]
            then
                printlog "Kernel signed successfully!"
                mv /boot/vmlinuz-"$KERNEL_VERSION"-generic /boot/vmlinuz-"$KERNEL_VERSION"-generic.unsigned
                mv /boot/vmlinuz-"$KERNEL_VERSION"-generic.signed /boot/vmlinuz-"$KERNEL_VERSION"-generic
                if ! { [ "$PRESERVE_UNSIGNED" ]; }
                then
                    sudo rm -f /boot/vmlinuz-"$KERNEL_VERSION"-generic.unsigned
                fi
                update-grub
                exit 
            else
                printlog "Kernel signature verification failed!"
                exit
            fi
        else
            printlog "'MOK.priv', 'MOK.pem' and 'MOK.der' does not exist or empty!"
            exit
        fi
    else
        printlog "No kernel with version $KERNEL_VERSION found!"
        exit
    fi
}

function generate_certs(){
    check_openssl
    printlog "Generating certificates..."
    if [ -s "./MOK.priv" ] && [ -s "./MOK.der" ] && [ -s "./MOK.pem" ]
    then
        printlog "Certificates already exist, skipping..."
    else
        if [ -s "./mokconfig.cnf" ]
        then
            openssl req -config ./mokconfig.cnf -new -x509 -newkey rsa:2048 -nodes -days 36500 -outform DER -keyout "MOK.priv" -out "MOK.der" >> log.txt 2>&1
            openssl x509 -in MOK.der -inform DER -outform PEM -out MOK.pem >> log.txt 2>&1
            
            # Check if generation succeeded
            if [ -s "./MOK.priv" ] && [ -s "./MOK.der" ] && [ -s "./MOK.pem" ]
            then
                printlog "Certificates generated! Store securely for future use."
            else
                printlog "Certificate-generation failed. Check 'log.txt'"
                exit
            fi
        else
            printlog "Unable to locate 'mokconfig.cnf'"
            exit
        fi
    fi
}

function enroll_mok(){
    check_mokutil
    printlog "Enrolling certificate in MOK..."
    if [ -s "./MOK.der" ]
    then
        IS_ENROLLED=$(mokutil --test-key MOK.der)
        if [[ "$IS_ENROLLED" == *"is already enrolled" ]]
        then
            printlog "'MOK.der' is already enrolled in MOK, skipping..."
        else
            printlog "Create a one time password (Can be anything, used to confirm enrollment at next reboot):"
            mokutil --import MOK.der
            if [ "$(mokutil --list-new)" == "MokNew is empty" ]
            then
                printlog "Failed to enroll certificate. Check log.txt"
                exit
            else
                printlog "Certificate enrollment successfully requested!"
                printlog "Reboot and select \"Enroll MOK\". Use the previously created password." 
            fi
        fi
    else
        printlog "'MOK.der' does not exist or is empty!"
        exit
    fi
}

function delete_mok(){
    check_mokutil
    printlog "Removing certificate from MOK..."
    if [ -s "./MOK.der" ]
    then
        IS_ENROLLED=$(mokutil --test-key MOK.der)
        if [[ "$IS_ENROLLED" == *"is already enrolled" ]]
        then
            printlog "Create a one time password (Can be anything, used to confirm deletion at next reboot):"
            mokutil --delete MOK.der
            if [ "$(mokutil --list-delete)" == "MokDel is empty" ]
            then
                printlog "Failed to remove certificate. Check log.txt"
                exit
            else
                printlog "Certificate deletion successfully requested!"
                printlog "Reboot and select \"Delete MOK\". Use the previously created password." 
            fi
        else
            printlog "Certificate not enrolled in MOK."
            exit
        fi
    else
        printlog "Could not delete certificate: 'MOK.der' does not exist or is empty!"
        exit
    fi
}

function list_kernels(){
    printlog "installed kernel-versions:"
    for filename in /boot/vmlinuz-*-generic
    do
        filename=${filename#*-}
        printlog "${filename%-*}"
    done
}

function execute(){
    if [ "$GENERATE_CERTS" ]
    then
        # Exit if wanting to enroll/sign but aren't sudo
        if [ "$ENROLL_MOK" ] || [ "$SIGN_KERNEL" ]
        then
            check_if_sudo
        fi
        generate_certs
    fi

    if [ "$ENROLL_MOK" ]
    then
        check_if_sudo
        enroll_mok
    fi

    if [ "$DELETE_MOK" ]
    then
        check_if_sudo
        delete_mok
    fi

    if [ "$SIGN_KERNEL" ]
    then
        check_if_sudo
        sign_kernel
    fi
}

function check_if_sudo(){
    if [ "$EUID" -ne 0 ]
    then
        printlog "Please run as root."
        exit
    fi
}

function check_sbsign(){
    if ! command -v sbsign &> /dev/null
    then
        printlog "sbsign could not be found."
        exit
    fi
    if ! command -v sbverify &> /dev/null
    then
        printlog "sbverify could not be found."
        exit
    fi
}

function check_mokutil(){
    if ! command -v mokutil &> /dev/null
    then
        printlog "mokutil could not be found."
        exit
    fi
}

function check_openssl(){
    if ! command -v openssl &> /dev/null
    then
        printlog "OpenSSL could not be found."
        exit
    fi
}

function printlog(){
    echo "$1" | tee -a "./log.txt"
}

# Begin main part
echo "${0##*/} $*" >> "./log.txt"
if [[ ${#} -eq 0 ]]; then
   usage
fi

# Define list of arguments expected in the input
optstring="hlpgedsa"
while getopts ${optstring} opt; do
    case $opt in
    h)  # Display usage
        usage
        exit
        ;;

    l)  # List installed kernels
        list_kernels
        exit
        ;;

    p)  # Preserve unsigned kernel
        PRESERVE_UNSIGNED=TRUE
        ;;

    g)  # Generate certs
        GENERATE_CERTS=TRUE
        ;;

    e)  # Enroll certs in MOK
        ENROLL_MOK=TRUE
        ;;

    d)  # Unroll certs from MOK
        DELETE_MOK=TRUE
        ;;

    s)  # Sign kernel
        if [[ -v OPTARG ]]
        then
            KERNEL_VERSION=$OPTARG
        fi
        SIGN_KERNEL=TRUE
        ;;

    a)  # Generate certs, enroll in MOK, and sign kernel
        if [[ -v OPTARG ]]
        then
            KERNEL_VERSION=$OPTARG
        fi
        GENERATE_CERTS=TRUE
        ENROLL_MOK=TRUE
        SIGN_KERNEL=TRUE
        ;;

    \?) # Handle errors
        printlog "Unknown option or missing a required argument."
        usage
        exit
        ;;
    esac
done

execute
