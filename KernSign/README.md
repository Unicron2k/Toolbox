
<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/Unicron2k/Toolbox/KernSign">
    <h1 align="center">KernSign</h3>
  </a>
</p>


<!-- ABOUT THE PROJECT -->
## About The Project
"KernSign" is a small utility-script that automates the signing of mainline Linux kernel-images for use with SecureBoot. Generates custom certificates, enrolls certificates in MOK, signs the kernel and updates GRUB.

#### Why I made this script
I got tired of manually enrolling keys and signing kernel-images. Other solutions probably exists, but I wanted to make my own.

> This script saves me multiple seconds multiple times per month!
> &emsp;- Me

## Usage
```
Usage: kernsign.sh [-p] -hlgedsS
   -h            Display usage
   -l            List installed kernels
  [-p]           Preserve unsigned kernel
   -g            Generate certificates
   -e            Enroll certificates in MOK
   -d            Delete certificates from MOK
   -s [version]  Sign kernel. Latest kernel wil be signed if no [version] specified
   -a [version]  Generate certificates, enroll in MOK and sign specified version
                 (equivalent to kernsign.sh -c -e -s [version] )
```
### Requirements:
 - openssl - Generate certificates
 - mokutil - Enroll certificate in MOK
 - sbsign  - Sign kernel-images

### First-time usage:
*IMPORTANT*: Remember to securely store your generated certificates (MOK.der, MOK.priv, MOK.pem) for future use.

1. Fill out mokconfig.cnf with your info.
2. Run `sudo ./kernsign.sh -a`
3. Follow the instructions to generate certificates, enroll them in MOK and sign latest installed kernel-image.
4. Once signed, reboot and select your newly signed kernel.
5. For subsequent signing of new kernel-images, use `sudo ./kernsign.sh -s`. This will sign the latest installed kernel, provided the previously generated MOK.priv, MOK.pem and MOK.der are located in the same folder as kernsign.sh


### Advanced usage
Refer to "usage" above or the help-command ( -h ) for advanced usage.
You can supply your own certificates to sign images by adding/replacing the following files in the KernSign-directory:
- MOK.der - Public certificate
- MOK.priv - Private key
- MOK.pem - Base64 ASCII-encoded public certificate

This is most common in larger organizations with corporate-supplied workstations.
Remember to enroll them in MOK with the `-e`-option.

<!-- LICENSE -->
## License
Subject to change.
All code is distributed under the MIT License.
See [`LICENSE.txt`](LICENSE.txt) for more information.


<!-- CONTACT -->
## Contact

Mail: [UnicronDev@outlook.com](mailto:UnicronDev@outlook.com)
Project Link: [https://github.com/Unicron2k/Toolbox/KernSign](https://github.com/Unicron2k/Toolbox/KernSign)
