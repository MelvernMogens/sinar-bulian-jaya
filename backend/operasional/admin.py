from django.contrib import admin
from .models import (
    Pelanggan, Nota, Pembayaran, BukuKasbon, 
    Pengeluaran, KasGudang, Pengiriman, ItemPengiriman,
    LotPabrik, UserProfile, LogAktivitas # <-- Tambahan import model baru
)

@admin.register(Pelanggan)
class PelangganAdmin(admin.ModelAdmin):
    list_display = ('nama', 'saldo_mengendap', 'total_kasbon')
    search_fields = ('nama',)

@admin.register(BukuKasbon)
class BukuKasbonAdmin(admin.ModelAdmin):
    list_display = ('pelanggan', 'tanggal', 'tipe_transaksi', 'nominal')
    list_filter = ('tipe_transaksi', 'tanggal')

@admin.register(Nota)
class NotaAdmin(admin.ModelAdmin):
    list_display = ('id', 'pelanggan', 'tanggal', 'berat_kg', 'harga_per_kg', 'status_bayar')
    list_filter = ('status_bayar', 'tanggal')
    search_fields = ('pelanggan__nama',)

@admin.register(Pembayaran)
class PembayaranAdmin(admin.ModelAdmin):
    list_display = ('nota', 'metode', 'nominal', 'tanggal_bayar', 'is_setoran_pinjaman')
    list_filter = ('metode', 'tanggal_bayar')

@admin.register(Pengeluaran)
class PengeluaranAdmin(admin.ModelAdmin):
    list_display = ('tanggal', 'kategori', 'nominal_total')
    list_filter = ('kategori', 'tanggal')

@admin.register(KasGudang)
class KasGudangAdmin(admin.ModelAdmin):
    list_display = ('tanggal', 'tipe_mutasi', 'nominal', 'keterangan')
    list_filter = ('tipe_mutasi', 'tanggal')

@admin.register(LotPabrik)
class LotPabrikAdmin(admin.ModelAdmin):
    list_display = ('nama_lot', 'tanggal_buat', 'pabrik', 'is_selesai')
    list_filter = ('is_selesai', 'tanggal_buat')
    search_fields = ('nama_lot', 'pabrik')

class ItemPengirimanInline(admin.TabularInline):
    model = ItemPengiriman
    extra = 0
    readonly_fields = ['harga_jual', 'total_harga']

@admin.register(Pengiriman)
class PengirimanAdmin(admin.ModelAdmin):
    list_display = ['id', 'tipe', 'get_judul', 'tanggal', 'status']
    list_filter = ['tipe', 'status', 'tanggal']
    search_fields = ['plat_mobil', 'nama_stock']
    inlines = [ItemPengirimanInline]

    def get_judul(self, obj):
        return obj.plat_mobil if obj.tipe == 'KIRIM' else obj.nama_stock
    get_judul.short_description = 'Plat / Nama Stock'

@admin.register(ItemPengiriman)
class ItemPengirimanAdmin(admin.ModelAdmin):
    list_display = ['id', 'pengiriman', 'pelanggan', 'tonase', 'harga_input', 'is_dibuat_nota']
    list_filter = ['is_dibuat_nota', 'pengiriman__tipe']
    search_fields = ['pelanggan__nama', 'pengiriman__plat_mobil']

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'role')
    list_filter = ('role',)

@admin.register(LogAktivitas)
class LogAktivitasAdmin(admin.ModelAdmin):
    list_display = ('waktu', 'user', 'modul', 'aksi', 'keterangan')
    list_filter = ('modul', 'aksi', 'waktu')
    search_fields = ('keterangan', 'user__username')