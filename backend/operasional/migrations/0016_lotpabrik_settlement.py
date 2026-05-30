# Settlement Pabrik: hitungan ABP + potongan-potongan (buat Net Gain/Loss bersih)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('operasional', '0015_lotpabrik_gilingan'),
    ]

    operations = [
        migrations.AddField(
            model_name='lotpabrik',
            name='hitungan_abp',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=18),
        ),
        migrations.AddField(
            model_name='lotpabrik',
            name='denda_pph',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
        migrations.AddField(
            model_name='lotpabrik',
            name='ppn',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
        migrations.AddField(
            model_name='lotpabrik',
            name='obm',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
        migrations.AddField(
            model_name='lotpabrik',
            name='materai',
            field=models.DecimalField(decimal_places=2, default=10000, max_digits=10),
        ),
        migrations.AddField(
            model_name='lotpabrik',
            name='potongan_lain',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=15),
        ),
    ]
