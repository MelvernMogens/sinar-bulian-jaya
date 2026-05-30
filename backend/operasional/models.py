from django.db import models
from django.utils import timezone
from decimal import Decimal
import math
from django.contrib.auth.models import User # <-- IMPORT USER BAWAAN DJANGO

class Pelanggan(models.Model):
    nama = models.CharField(max_length=100)
    no_telp = models.CharField(max_length=30, blank=True, null=True)
    no_rekening = models.CharField(max_length=60, blank=True, null=True)
    saldo_mengendap = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_kasbon = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nama


class RekeningPetani(models.Model):
    """Satu petani bisa punya banyak rekening (nomor + atas nama)."""
    pelanggan = models.ForeignKey(Pelanggan, on_delete=models.CASCADE, related_name='rekening_list')
    nomor = models.CharField(max_length=60)
    atas_nama = models.CharField(max_length=120, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['atas_nama', 'id']

    def __str__(self):
        return f"{self.atas_nama or '(tanpa nama)'} - {self.nomor}"

class Nota(models.Model):
    STATUS_PILIHAN = [('LUNAS', 'Lunas'), ('BB', 'Belum Bayar (BB)')]

    pelanggan = models.ForeignKey(Pelanggan, on_delete=models.CASCADE)
    tanggal = models.DateTimeField(default=timezone.now)
    berat_kg = models.DecimalField(max_digits=10, decimal_places=2)
    harga_per_kg = models.DecimalField(max_digits=10, decimal_places=2)
    biaya_materai = models.DecimalField(max_digits=10, decimal_places=2, default=6000)

    pakai_komisi = models.BooleanField(default=True)
    pakai_buruh = models.BooleanField(default=True)
    pakai_materai = models.BooleanField(default=True)

    status_bayar = models.CharField(max_length=10, choices=STATUS_PILIHAN, default='LUNAS')

    # Link ke ItemPengiriman supaya edit nota bisa sync ke laporan pengiriman
    item_pengiriman = models.ForeignKey(
        'ItemPengiriman', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='nota_set'
    )
    
    @property
    def total_kotor(self):
        return self.berat_kg * self.harga_per_kg

    @property
    def potongan_komisi(self):
        if not self.pakai_komisi: 
            return Decimal('0')
        val = float(self.total_kotor) * 0.01
        return Decimal(str(math.ceil(val / 1000.0) * 1000))

    @property
    def potongan_buruh(self):
        if not self.pakai_buruh: 
            return Decimal('0')
        val = float(self.berat_kg) * 35.0
        return Decimal(str(math.ceil(val / 1000.0) * 1000))

    @property
    def nilai_materai(self):
        return self.biaya_materai if self.pakai_materai else Decimal('0')

    @property
    def total_bersih(self):
        kotor = self.total_kotor
        bersih = kotor - self.potongan_komisi - self.potongan_buruh - self.nilai_materai
        return Decimal(str(math.floor(float(bersih) / 1000.0) * 1000))

    def __str__(self):
        return f"Nota {self.id} - {self.pelanggan.nama}"

class Pembayaran(models.Model):
    METODE_PILIHAN = [('CASH', 'Cash'), ('TRANSFER', 'Transfer'), ('AMPERA', 'Ampera')]
    nota = models.ForeignKey(Nota, on_delete=models.CASCADE)
    metode = models.CharField(max_length=10, choices=METODE_PILIHAN)
    nominal = models.DecimalField(max_digits=12, decimal_places=2)
    tanggal_bayar = models.DateTimeField(default=timezone.now)
    keterangan = models.TextField(blank=True, null=True)
    is_setoran_pinjaman = models.BooleanField(default=False)
    is_selesai = models.BooleanField(default=False)
    # Snapshot rekening tujuan kalau metode TRANSFER (disimpan saat dipilih,
    # tetap kebaca walau rekening petani dihapus belakangan).
    rekening_nomor = models.CharField(max_length=60, blank=True, null=True)
    rekening_atas_nama = models.CharField(max_length=120, blank=True, null=True)

class BukuKasbon(models.Model):
    TIPE_PILIHAN = [('PINJAM', 'Pinjaman Baru'), ('SETOR', 'Setoran')]
    pelanggan = models.ForeignKey(Pelanggan, on_delete=models.CASCADE)
    tanggal = models.DateField(default=timezone.now)
    tipe_transaksi = models.CharField(max_length=10, choices=TIPE_PILIHAN)
    nominal = models.DecimalField(max_digits=12, decimal_places=2)
    keterangan = models.CharField(max_length=255)

class Pengeluaran(models.Model):
    KATEGORI_PILIHAN = [
        ('MAKAN', 'Uang Makan'), ('BURUH', 'Ongkos Buruh Harian'),
        ('ONGKIR', 'Ongkos Kirim'), ('BURUH_TAMBAHAN', 'Buruh Tambahan'),
        ('UANG_JALAN', 'Uang Jalan'), ('MINYAK', 'Minyak Mobil'),
        ('SUMBANGAN', 'Sumbangan'), ('GAJI', 'Gaji Bulanan'), ('LAIN', 'Lain-lain')
    ]
    tanggal = models.DateField(default=timezone.now)
    kategori = models.CharField(max_length=20, choices=KATEGORI_PILIHAN)
    nominal_total = models.DecimalField(max_digits=12, decimal_places=2)
    keterangan = models.TextField(help_text="Isi detail seperti plat mobil, nama karyawan, atau jumlah orang")

class KasGudang(models.Model):
    TIPE_MUTASI = [('MASUK', 'Uang Masuk'), ('KELUAR', 'Uang Keluar')]
    tanggal = models.DateField(default=timezone.now)
    tipe_mutasi = models.CharField(max_length=10, choices=TIPE_MUTASI)
    nominal = models.DecimalField(max_digits=15, decimal_places=2)
    keterangan = models.CharField(max_length=255)


class LotPabrik(models.Model):
    nama_lot = models.CharField(max_length=100)
    tanggal_buat = models.DateField(default=timezone.now)
    pabrik = models.CharField(max_length=100, blank=True, null=True)
    bl = models.CharField(max_length=50, blank=True, null=True)  # legacy (sekarang BL dihitung otomatis)
    vm = models.CharField(max_length=50, blank=True, null=True)  # legacy (sekarang VM dihitung otomatis)
    gilingan_basah = models.DecimalField(max_digits=15, decimal_places=2, default=0)   # input manual -> BL = tonase pabrik / gilingan basah
    gilingan_kering = models.DecimalField(max_digits=15, decimal_places=2, default=0)  # input manual -> VM = gilingan kering / BL
    harga_jual_pabrik = models.DecimalField(max_digits=15, decimal_places=2, default=0)  # harga jual dasar dari pabrik per kg
    # --- Settlement Pabrik (buat hitung Net Gain/Loss bersih) ---
    hitungan_abp = models.DecimalField(max_digits=18, decimal_places=2, default=0)   # nilai final dari pabrik (input dari invoice)
    denda_pph = models.DecimalField(max_digits=15, decimal_places=2, default=0)      # denda PPh 22 (kalau ada)
    ppn = models.DecimalField(max_digits=15, decimal_places=2, default=0)            # PPN
    obm = models.DecimalField(max_digits=15, decimal_places=2, default=0)            # ongkos bongkar muat
    materai = models.DecimalField(max_digits=10, decimal_places=2, default=10000)    # default 10000
    potongan_lain = models.DecimalField(max_digits=15, decimal_places=2, default=0)  # catch-all potongan lain
    is_selesai = models.BooleanField(default=False)

    @property
    def total_uang_lot_gudang(self):
        total = Decimal('0')
        for p in self.pengiriman_set.all():
            for item in p.items.all():
                total += item.total_harga
        return total

    @property
    def total_tonase_pabrik_lot(self):
        total = Decimal('0')
        for p in self.pengiriman_set.all():
            total += p.tonase_pabrik
        return total

    @property
    def harga_modal_asli(self):
        tonase_pabrik = self.total_tonase_pabrik_lot
        if tonase_pabrik > Decimal('0'):
            return self.total_uang_lot_gudang / tonase_pabrik
        return Decimal('0')

    def __str__(self):
        return self.nama_lot

class Pengiriman(models.Model):
    TIPE_CHOICES = (('KIRIM', 'Kirim Mobil'), ('STOCK', 'Timbang Taruh'))
    STATUS_CHOICES = (('DRAFT', 'Sedang Dimuat'), ('TERKIRIM', 'Selesai/Terkirim'))
    
    lot = models.ForeignKey(LotPabrik, on_delete=models.SET_NULL, null=True, blank=True, related_name='pengiriman_set')
    tipe = models.CharField(max_length=10, choices=TIPE_CHOICES)
    plat_mobil = models.CharField(max_length=20, null=True, blank=True)
    nama_stock = models.CharField(max_length=20, null=True, blank=True)
    tanggal = models.DateField(auto_now_add=True)  # tanggal dibuat (timbang)
    tanggal_kirim = models.DateField(null=True, blank=True)  # tanggal saat difinalisasi/dikirim
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='DRAFT')

    tonase_pabrik = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    def __str__(self):
        return str(self.plat_mobil) if self.tipe == 'KIRIM' else str(self.nama_stock)

class ItemPengiriman(models.Model):
    pengiriman = models.ForeignKey(Pengiriman, on_delete=models.CASCADE, related_name='items')
    pelanggan = models.ForeignKey(Pelanggan, on_delete=models.SET_NULL, null=True, blank=True)
    nama_tujuan = models.CharField(max_length=100, blank=True, null=True) 
    tonase = models.DecimalField(max_digits=10, decimal_places=2)
    harga_input = models.DecimalField(max_digits=15, decimal_places=2)
    harga_jual = models.DecimalField(max_digits=15, decimal_places=2) 
    total_harga = models.DecimalField(max_digits=15, decimal_places=2) 
    is_dibuat_nota = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.nama_tujuan} - {self.tonase} kg"

class UserProfile(models.Model):
    ROLE_CHOICES = (
        ('KASIR', 'Kasir'),
        ('OWNER', 'Owner'),
    )
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='KASIR')

    def __str__(self):
        return f"{self.user.username} - {self.role}"

class LogAktivitas(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    waktu = models.DateTimeField(default=timezone.now)
    modul = models.CharField(max_length=50) 
    aksi = models.CharField(max_length=50) 
    keterangan = models.TextField() 

    def __str__(self):
        username = self.user.username if self.user else "Sistem"
        return f"[{self.waktu.strftime('%d-%m-%Y %H:%M')}] {username} - {self.aksi} {self.modul}"