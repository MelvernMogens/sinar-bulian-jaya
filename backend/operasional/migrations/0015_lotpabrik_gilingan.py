# Gilingan pabrik basah & kering (buat auto-calc BL & VM)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('operasional', '0014_lotpabrik_harga_jual_pabrik'),
    ]

    operations = [
        migrations.AddField(
            model_name='lotpabrik',
            name='gilingan_basah',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
        migrations.AddField(
            model_name='lotpabrik',
            name='gilingan_kering',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
    ]
