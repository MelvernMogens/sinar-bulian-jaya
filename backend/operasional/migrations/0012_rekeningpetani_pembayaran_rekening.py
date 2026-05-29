# Rekening petani (multi) + snapshot rekening di Pembayaran

from django.db import migrations, models
import django.db.models.deletion


def migrate_no_rekening(apps, schema_editor):
    """Pindahkan Pelanggan.no_rekening yang sudah ada jadi 1 RekeningPetani."""
    Pelanggan = apps.get_model('operasional', 'Pelanggan')
    RekeningPetani = apps.get_model('operasional', 'RekeningPetani')
    for p in Pelanggan.objects.exclude(no_rekening__isnull=True).exclude(no_rekening__exact=''):
        nomor = (p.no_rekening or '').strip()
        if not nomor:
            continue
        # Hindari duplikat kalau migration dijalankan ulang
        if not RekeningPetani.objects.filter(pelanggan=p, nomor=nomor).exists():
            RekeningPetani.objects.create(pelanggan=p, nomor=nomor, atas_nama='')


def reverse_noop(apps, schema_editor):
    # Tidak menghapus apa-apa saat rollback (data aman).
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('operasional', '0011_pelanggan_no_rekening_pelanggan_no_telp'),
    ]

    operations = [
        migrations.CreateModel(
            name='RekeningPetani',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nomor', models.CharField(max_length=60)),
                ('atas_nama', models.CharField(blank=True, default='', max_length=120)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('pelanggan', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='rekening_list', to='operasional.pelanggan')),
            ],
            options={
                'ordering': ['atas_nama', 'id'],
            },
        ),
        migrations.AddField(
            model_name='pembayaran',
            name='rekening_nomor',
            field=models.CharField(blank=True, max_length=60, null=True),
        ),
        migrations.AddField(
            model_name='pembayaran',
            name='rekening_atas_nama',
            field=models.CharField(blank=True, max_length=120, null=True),
        ),
        migrations.RunPython(migrate_no_rekening, reverse_noop),
    ]
