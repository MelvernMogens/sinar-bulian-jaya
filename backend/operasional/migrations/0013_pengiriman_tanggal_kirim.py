# Tambah tanggal_kirim di Pengiriman (tanggal saat difinalisasi/dikirim)

from django.db import migrations, models


def backfill_tanggal_kirim(apps, schema_editor):
    """Pengiriman yang sudah TERKIRIM: set tanggal_kirim = tanggal (best guess)."""
    Pengiriman = apps.get_model('operasional', 'Pengiriman')
    for p in Pengiriman.objects.filter(status='TERKIRIM', tanggal_kirim__isnull=True):
        p.tanggal_kirim = p.tanggal
        p.save(update_fields=['tanggal_kirim'])


def reverse_noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('operasional', '0012_rekeningpetani_pembayaran_rekening'),
    ]

    operations = [
        migrations.AddField(
            model_name='pengiriman',
            name='tanggal_kirim',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.RunPython(backfill_tanggal_kirim, reverse_noop),
    ]
