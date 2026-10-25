# MacBook8,1 (12" 2015): keyboard and trackpad dead after suspend on Linux

[Türkçe açıklama aşağıda](#türkçe)

On the 12" MacBook (MacBook8,1) the built-in keyboard and trackpad are connected over SPI and driven by the `applespi` kernel driver. After resuming from S3 ("deep") suspend, the SPI controller stops responding and both devices are dead until a reboot. The kernel log fills with:

```
applespi spi-APP000D:00: SPI transfer timed out
spi_master spi1: failed to transfer one message from queue
applespi spi-APP000D:00: Error reading from device: -110
applespi spi-APP000D:00: Error writing to device: -110
```

## Fix

Use s2idle (suspend-to-idle) instead of S3 deep sleep. The SPI controller keeps its state and input works after resume.

```sh
git clone https://github.com/hakanseyhan92/macbook8-1-linux-suspend-fix
cd macbook8-1-linux-suspend-fix
sudo ./install.sh
```

Or by hand:

```sh
sudo mkdir -p /etc/systemd/sleep.conf.d
printf '[Sleep]\nSuspendState=freeze\n' | sudo tee /etc/systemd/sleep.conf.d/s2idle.conf
```

No reboot is needed. Test with `systemctl suspend`, then wake the machine with a key, the power button or by opening the lid.

### Remove module-reload workarounds

A common workaround found online is a systemd service that, after resume, unbinds `applespi` and reloads `applespi`, `spi_pxa2xx_*` and `intel_lpss_pci`. It never fixed the S3 problem, and with s2idle it actively breaks input: it unbinds the keyboard, then `modprobe -r` fails because the modules are in use, and the keyboard can stay detached. If you have such a service, disable it:

```sh
systemctl list-unit-files | grep -iE 'spi|applespi|resume'
sudo systemctl disable --now <service-name>
```

### Alternative: kernel parameter

Instead of the systemd config you can make s2idle the kernel default, which also covers suspends that bypass systemd. Add `mem_sleep_default=s2idle` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, then run `sudo update-grub` and reboot.

## Verify

```sh
cat /sys/power/mem_sleep                     # the kernel default, may still show [deep]
journalctl -b -k | grep -E 'PM: suspend|applespi'
```

After a suspend you should see `PM: suspend entry (s2idle)` followed by `PM: suspend exit`, and no `SPI transfer timed out` lines.

## Trade-offs

s2idle uses more power while asleep than S3. That matters little when the laptop stays on AC power. On battery, expect a faster drain overnight.

With a worn-out battery, if the charger is unplugged or the power fails during sleep, the machine turns off completely. That looks like "it did not wake up", but it is a power loss, not this bug.

## Undo

```sh
sudo rm /etc/systemd/sleep.conf.d/s2idle.conf
```

## Tested on

- MacBook8,1 (Retina, 12-inch, Early 2015)
- Linux Mint 22.3 Xfce, kernel 7.0.0-38-generic (the bug was also seen on 7.0.0-30-generic)

Reports from other models with `applespi` (MacBook9,1, MacBook10,1, MacBookPro13,x/14,x) are welcome.

---

## Türkçe

12" MacBook'ta (MacBook8,1) dahili klavye ve trackpad SPI üzerinden bağlıdır ve `applespi` sürücüsüyle çalışır. S3 ("deep") uykudan uyandıktan sonra SPI denetleyicisi yanıt vermez, klavye ve trackpad yeniden başlatana kadar çalışmaz. Kernel loglarında `SPI transfer timed out` ve `Error reading from device: -110` hataları görülür.

**Çözüm:** S3 yerine s2idle uyku modunu kullanmak.

```sh
sudo ./install.sh
```

veya elle:

```sh
sudo mkdir -p /etc/systemd/sleep.conf.d
printf '[Sleep]\nSuspendState=freeze\n' | sudo tee /etc/systemd/sleep.conf.d/s2idle.conf
```

Uyandıktan sonra `applespi` ve `intel_lpss` modüllerini yeniden yükleyen bir servis kullanıyorsanız onu kapatın (`sudo systemctl disable --now <servis-adı>`). Bu tür servisler sorunu çözmez, s2idle ile birlikte klavyeyi bozar.

s2idle uykuda S3'ten biraz daha fazla enerji harcar. Sürekli şarjda kullanılan bir dizüstü için fark önemsizdir. Pil yıpranmışsa ve uykudayken şarj kablosu çıkarsa bilgisayar tamamen kapanır. Bu durum sorunun tekrar etmesi değil, güç kesintisidir.

Geri almak için: `sudo rm /etc/systemd/sleep.conf.d/s2idle.conf`
