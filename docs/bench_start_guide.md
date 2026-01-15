# Panduan Menjalankan Bench Start

Dokumen ini menjelaskan langkah-langkah untuk menjalankan server Frappe/ERPNext menggunakan perintah `bench start` dari Windows PowerShell (melalui WSL).

## Prasyarat
- Windows Subsystem for Linux (WSL) sudah terinstall.
- Frappe Bench sudah terinstall di dalam WSL.

## Langkah-langkah

### 1. Buka PowerShell
1.  Tekan tombol **Windows** di keyboard.
2.  Ketik **PowerShell**.
3.  Pilih **Windows PowerShell** atau **Terminal**.

### 2. Masuk ke Lingkungan Linux (WSL)
Frappe Framework berjalan di lingkungan Linux. Ketik perintah berikut di PowerShell untuk masuk ke terminal Linux Anda:

```powershell
wsl
```
*Atau jika Anda memiliki distro spesifik:*
```powershell
wsl -d Ubuntu
```


### 2.5 Masuk ke User Frappe (Jika Diperlukan)
Jika instalasi bench Anda berada di bawah user `frappe` (bukan user default WSL Anda), jalankan perintah ini untuk berpindah user:

```bash
sudo su - frappe
```
*Masukkan password WSL Anda jika diminta.*

### 3. Masuk ke Direktori Bench
Arahkan ke folder tempat `frappe-bench` diinstall. Biasanya folder ini berada di direktori `home` pengguna Anda.

1.  Cek daftar folder:
    ```bash
    ls
    ```
2.  Masuk ke direktori bench (sesuaikan `frappe-bench` dengan nama folder Anda):
    ```bash
    cd frappe-bench
    ```

### 4. Jalankan Server
Setelah berada di dalam folder bench, jalankan perintah berikut untuk memulai server:

```bash
bench start
```

### 5. Akses Aplikasi
Tunggu hingga proses booting selesai (biasanya terlihat log berwarna-warni dari `web`, `worker`, `redis`, dll).
Buka browser Anda dan akses:

*   **URL**: [http://localhost:8000](http://localhost:8000)

---

## Troubleshooting

### Port Konflik (Address already in use)
Jika muncul error bahwa port 8000 atau redis (11000/13000) sedang digunakan:
1.  Pastikan tidak ada instance bench lain yang berjalan.
2.  Cari proses yang memblock port:
    ```bash
    sudo lsof -i :8000
    ```
3.  Kill proses tersebut jika perlu, atau restart WSL:
    ```powershell
    wsl --shutdown
    ```

### Menghentikan Server
Untuk mematikan `bench start`:
1.  Klik pada jendeal terminal tempat bench berjalan.
2.  Tekan tombol **Ctrl + C**.
