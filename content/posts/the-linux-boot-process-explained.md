---
title: 'The Linux Boot Process Explained'
date: 2023-04-05T10:32:32+01:00
authors: ['maciej.opalinski']
tags: ['linux']
---

## Introduction

If you are reading this, you probably used Linux before. No matter if you are running some Linux distribution as a daily driver or not, you might use an Android phone that is using the Linux kernel. You also requested this website content from a server running Linux. But did you ever wonder how Linux works? In this article, I am going to explain one of the most fundamental aspects of Linux - its boot process.

## BIOS/UEFI Firmware

When you power on your computer, the first thing that happens is the BIOS or UEFI firmware (depending on your system) initializes the hardware and performs a [Power-On Self-Test](https://en.wikipedia.org/wiki/Power-on_self-test) to ensure that all components are functioning correctly. The BIOS/UEFI firmware then looks for a boot device, typically a HDD or SDD, where the operating system is installed.

### BIOS vs UEFI

I found a great comparison of BIOS and UEFI [posted by u/AiwendilH on r/linux](https://www.reddit.com/r/linux/comments/4o1nao/comment/d48subj/). Below is an excerpt from the comment explaining how BIOS and UEFI work:

#### BIOS (Basic Input/Output System)

> "Let's look at the first sector of the first hard disk and boot the kernel saved in it."
>
> "We are not in the 80s anymore... no kernel fits in the boot sector nowadays."
>
> "Then, let's try booting a tiny kernel that loads the real kernel... we can call it a boot manager."
>
> "Nice, this works... but what if we want to boot another OS?"
>
> "We already have the boot manager, let's just add a menu to it to choose what kernel it should boot."
>
> "Mhhh, but those kernels are on different filesystems like ext2 or FAT."
>
> "Well... let's add filesystem drivers to our boot manager."
>
> "But now the boot manager is too big to fit in the boot sector... we are back at square one."
>
> "Let's use the empty sectors before the first partition as well... we assume that those are unused and only needed for partition alignment... that gives us some more space."
>
> -- <cite>[u/AiwendilH on r/linux](https://www.reddit.com/r/linux/comments/4o1nao/comment/d48subj/)</cite>

This is not a good solution. The boot manager falls apart in certain conditions. For more information, read [the entire comment thread](https://www.reddit.com/r/linux/comments/4o1nao/comment/d48subj/).

Also I'm pretty sure that no kernel ever fit in the 512 byte boot sector, so a true "BIOS boot" has not been around for years on any modern machines. So we might as well already move to UEFI.

#### UEFI (Unified Extensible Firmware Interface)

> "Okay, the BIOS was bad, let's make it better."
>
> "We support loading kernels from partitions right away... let's go with something simple for the filesystem format... like FAT32."
>
> -- <cite>[u/AiwendilH on r/linux](https://www.reddit.com/r/linux/comments/4o1nao/comment/d48subj/)</cite>

Basically, UEFI is more modern, faster and less problematic to setup. Just use UEFI.

There is much more going into UEFI, for example Secure Boot that was quite controversial. The original comment has some factual errors explaining how Secure Boot was introduced and how it's used. If you want to know more, please read [the entire comment thread](https://www.reddit.com/r/linux/comments/4o1nao/comment/d48subj/).

## Bootloader

The bootloader is responsible for loading the kernel into memory. The most common bootloader is GRUB (GRand Unified Bootloader). It provides a menu of boot options if multiple operating systems or kernels are installed. The bootloader also loads any necessary drivers for hardware components that are required to access the boot device.

You can use GRUB to choose which operating system to boot (Linux, Windows, etc.) and which kernel to load into memory. When you upgrade the kernel, most Linux distributions don't actually remove the old kernel. This is done in case the newly upgraded kernel fails to boot, then you can just go into advanced options in GRUB and choose a different kernel that works.

## Linux Kernel

Once the bootloader has loaded, it locates the Linux kernel and loads it into memory. The kernel is the core component of the operating system. It is responsible for managing system resources such as CPU, memory, input/output (I/O) devices and many more. The kernel also initializes system services and device drivers.

## Initramfs

After loading the kernel, the system then loads the initramfs (initial RAM filesystem). The initramfs is a temporary filesystem used to initialize and load other device drivers, optionally handle decryption and finally mount the actual root file system. The first program that is executed by the Linux kernel after loading initramfs is the `/init` executable.

We can explore the initramfs of our Linux installation. It is usually found in the `/boot` directory.

In my Arch Linux install, I have the following files in the `/boot` directory:

```
$ tree /boot
/boot
├── efi
│   ├── EFI
│   │   ├── Boot
│   │   │   ├── bootx64.efi
│   │   │   ├── fbx64.efi
│   │   │   └── mmx64.efi
│   │   ├── grub_uefi
│   │   │   └── grubx64.efi
│   │   └── Microsoft
│   │       ├── Boot
│   │           (...)
├── grub
│   (...)
│   ├── grub.cfg
│   (...)
├── initramfs-linux-fallback.img
├── initramfs-linux.img
(...)
└── vmlinuz-linux
```

I replaced some unimportant files with `(...)`.

Let's explain what every file and directory is for:

- `efi/` is the directory to which my EFI partition mounts. I'm running UEFI, so GRUB bootloader lives there along with the default Windows Boot Manager;
- `grub/` is the directory in which GRUB keeps its config files, like `grub.cfg`;
- `initramfs-linux.img` and `initramfs-linux-fallback.img` are the initramfs images themselves;
- `vmlinuz-linux` is the compressed Linux kernel, there instead could be `vmlinux-linux` which is uncompressed Linux kernel.

Let's explore the initramfs image!

### Exploring initramfs

The simplest method of extracting the initramfs image is to use the `lsinitcpio` tool from `mkinitcpio` package.

```shell
mkdir initramfs/
cd initramfs/
sudo cp /boot/initramfs-linux.img ./ # working on a copy
sudo chown $USER:$USER ./initramfs-linux.img # to avoid extracting with sudo
lsinitcpio -x initramfs-linux.img # extract to the current directory, run without the -x flag to just list the files
```

First thing that the Linux kernel executes is the `/init` script, so let's have a look at it.

```shell
#!/usr/bin/ash
# SPDX-License-Identifier: GPL-2.0-only

export PATH='/usr/local/sbin:/usr/local/bin:/usr/bin'

# !!! redacted !!!

mount_handler=default_mount_handler
init=/sbin/init

# !!! redacted !!!

. /init_functions

mount_setup

# parse the kernel command line
parse_cmdline </proc/cmdline

# !!! redacted !!!

# Mount root at /new_root
"$mount_handler" /new_root

# !!! redacted !!!

exec env -i \
    "TERM=$TERM" \
    /usr/bin/switch_root /new_root "$init" "$@"

# vim: set ft=sh ts=4 sw=4 et:
```

I redacted some of the less important parts of the script. Let's analyze the script line by line.

First, we are exporting a `PATH` environmental variable with default locations of all executables. We need it for our shell to locate the executables without typing out their entire paths by ourselves.

Then, we are defining some other variables that will be used later in the script.

Next, we evaluate the `/init_functions` script. The script is much longer and contains many functions used in the `/init` script, such as: `default_mount_handler`, `parse_cmdline`, etc.

After that, we call `mount_setup` from the mentioned `/init_functions` script. Here is how the function looks:

```shell
mount_setup() {
    mount -t proc proc /proc -o nosuid,noexec,nodev
    mount -t sysfs sys /sys -o nosuid,noexec,nodev
    mount -t devtmpfs dev /dev -o mode=0755,nosuid
    mount -t tmpfs run /run -o nosuid,nodev,mode=0755
    mkdir -m755 /run/initramfs

    if [ -e /sys/firmware/efi ]; then
        mount -t efivarfs efivarfs /sys/firmware/efi/efivars -o nosuid,nodev,noexec
    fi

    # Setup /dev symlinks
    if [ -e /proc/kcore ]; then
        ln -sfT /proc/kcore /dev/core
    fi
    ln -sfT /proc/self/fd /dev/fd
    ln -sfT /proc/self/fd/0 /dev/stdin
    ln -sfT /proc/self/fd/1 /dev/stdout
    ln -sfT /proc/self/fd/2 /dev/stderr
}
```

It basically mount all required system directories like `/proc`, `/sys`, etc.

Next step is quite interesting, because we are calling `parse_cmdline` function. The function makes sure that the Linux boot params are easily accessible as shell variables from inside the script. This is done for convenience purposes. I won't show the entire function, as it is rather complicated. After verifying that the shell variable is valid it just calls eval in the following way:

```shell
eval "$key"='${value:-y}'
```

Finally, we can mount our real root filesystem, where all our persistent files are stored. We call `$mount_handler`, which was previously defined as `default_mount_handler`. Here is the function definition:

```shell
default_mount_handler() {
    msg ":: mounting '$root' on real root"
    if ! mount -t "${rootfstype:-auto}" -o "${rwopt:-ro}${rootflags:+,$rootflags}" "$root" "$1"; then
        echo "You are now being dropped into an emergency shell."
        # shellcheck disable=SC2119
        launch_interactive_shell
        msg "Trying to continue (this will most likely fail) ..."
    fi
}
```

The function tries to mount the root filesystem to `/new_root` and will drop th euser into an emergency shell if something goes wrong.

Where does the `$root` variable come from? It comes from the previous step when we called `parse_cmdline`.

The final step in the `/init` script is to execute `/usr/bin/switch_root` to obviously chroot into the `/new_root` directory that contains our actual files and programs. The next argument is the path to the executable to be launched next (`$init`, previously defined as `/sbin/init`). This is the path from our actual root filesystem.

```
$ ls -la /sbin/init
lrwxrwxrwx 1 root root 22 Mar 29 20:41 /sbin/init -> ../lib/systemd/systemd
```

As we can see, in my case, the `/sbin/init` is linked to `/lib/systemd/systemd` as I am running systemd as my init system.

This was just an example `/init` script from my Arch Linux install. Yours might be different. You can even write your own `/init`! More on that in an upcoming article!

## Init System

Once the Linux kernel executes `/sbin/init`, the init system takes over. The init system is responsible for starting system services, such as networking, logging as well as running any startup scripts required by the system. The most popular init systems used in Linux are: [systemd](https://en.wikipedia.org/wiki/Systemd), [OpenRC](https://en.wikipedia.org/wiki/OpenRC), [runit](https://en.wikipedia.org/wiki/Runit).

## Conclusion

In conclusion, the Linux boot process is a complex sequence of steps that starts with the BIOS/UEFI firmware initializing the hardware and performing a Power-On Self-Test (POST), followed by the bootloader loading the Linux kernel into memory. The kernel initializes system resources, loads necessary device drivers, and hands over control to the init system, which starts system services and user applications. Understanding the Linux boot process is essential for troubleshooting and diagnosing problems with the operating system.
