# Tambah harga jual dasar pabrik per LOT

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('operasional', '0013_pengiriman_tanggal_kirim'),
    ]

    operations = [
        migrations.AddField(
            model_name='lotpabrik',
            name='harga_jual_pabrik',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
    ]
