#!/bin/sh
# Switch suspend from S3 "deep" to s2idle so applespi survives resume on MacBook8,1.
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./install.sh" >&2
    exit 1
fi

dir=$(dirname "$0")
install -D -m 644 "$dir/etc/systemd/sleep.conf.d/s2idle.conf" /etc/systemd/sleep.conf.d/s2idle.conf
echo "Installed /etc/systemd/sleep.conf.d/s2idle.conf"

if ! grep -qw s2idle /sys/power/mem_sleep; then
    echo "Warning: this kernel does not offer s2idle (/sys/power/mem_sleep: $(cat /sys/power/mem_sleep))" >&2
fi

echo "Done. Test with: systemctl suspend"
echo "If you added a resume hook that reloads applespi/intel_lpss modules, disable it (see README)."
