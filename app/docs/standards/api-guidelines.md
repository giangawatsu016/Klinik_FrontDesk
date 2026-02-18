# API Guideline

# Naming Convention

Referensi:

* [https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design) (diakses pada 21 Agustus 2025\)  
* [https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/) (diakses pada 21 Agustus 2025\)  
* Gemini (diakses pada 21 Agustus 2025\)  
* Claude Sonnet 4

Konvensi penamaan mampu meningkatkan kejelasan, konsistensi, dan kesesuaian terhadap prinsip-prinsip yang telah umum digunakan sehingga mempermudah developer dalam menggunakan dan memelihara API. Berikut adalah beberapa konvensi tersebut.

1. **Jangan gunakan kata kerja**  
   Suatu endpoint harus dinyatakan sebagai operasi terhadap suatu resource. Dengan demikian, nama endpoint harus menggunakan kata benda, bukan kata kerja. Aksi terhadap resource terkait akan sudah dinyatakan dalam bentuk metode HTTP (GET, POST, PUT, DELETE).  
   * **Bagus:** /users  
   * **Buruk:** /getUsers

   

2. **Gunakan kata benda jamak**  
   Resource yang bisa dioperasikan dalam bentuk koleksi (array) harus dinyatakan dengan kata benda jamak. Karena sebagian besar resource biasanya bisa dioperasikan dalam bentuk koleksi, kata benda jamak hampir akan selalu digunakan.  
   * **Bagus:** /products (untuk kumpulan produk), /users (untuk kumpulan user)  
   * **Buruk:** /product

   

3. **Gunakan format “kata benda jamak/{identifier}” untuk resource singleton**  
   Untuk endpoint yang melakukan operasi terhadap resource secara satuan, gunakan kata benda jamak yang diikuti dengan identifier.  
   * **Bagus:** /users/{id} atau /products/123

   

4. **Gunakan kebab case**  
   Pada kebab case, semua huruf harus ditulis dalam huruf kecil dan nama yang terdiri lebih dari satu kata harus ditulis dengan tanda hubung “-”. Hindari penggunaan camel case dan snake case.  
   * **Bagus:** /user-accounts (kebab case)  
   * **Buruk:** /UserAccounts (camel case), /user\_accounts (snake case)

   

5. **Struktur hirarkis**  
   Untuk endpoint yang mencerminkan hubungan antara resource, gunakan format “parent-resource/parent-resource-identifier/child-resource”.  
   * **Bagus:** /departments/{departmentId}/lectures

   

   Hindari penggunaan struktur hirarkis yang melibatkan lebih dari 2 level.

   * **Buruk:** /departments/1/lectures/123/professor

   Jika level hirarki yang lebih dalam benar-benar diperlukan, gunakan sistem [HATEOAS](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design#implement-hateoas).

   

6. **Gunakan query parameter untuk filter, sort, dan pagination**  
   Jangan membuat endpoint terpisah untuk ketiga hal ini.  
   * **Bagus:** /products?category=elektronik\&sort=harga\&limit=25\&offset=50

   

   Untuk mencegah serangan denial-of-service, pastikan batas atas untuk parameter “limit” dipasang. 

   

   Jika kondisi filter terlalu panjang atau kompleks sehingga tidak memungkinkan untuk dinyatakan di dalam query parameter, developer dianjurkan untuk mengganti method endpoint menjadi POST dan memindahkan query ke request body.

   

7. **Versioning**  
   Pisahkan endpoint berdasarkan versi untuk memungkinkan klien melakukan migrasi dan rollback versi tanpa interupsi dari sisi penyedia API.  
   * **Contoh versioning melalui penamaan endpoint:**   
     /v1/users  
     /v2/users  
       
   * **Contoh versioning dengan query parameter**  
     https://my.api.com/users?version=1  
     https://my.api.com/users?version=2

   * **Contoh versioning melalui request header:**   
     GET https://my.api.com/users  
     X-API-VERSION: 1  
       
     GET https://my.api.com/users  
     X-API-VERSION: 2  
     

   Versioning melalui penamaan endpoint dan query parameter lebih cache-friendly dibandingkan dengan request header karena mekanisme caching biasanya menggunakan URI atau query string sebagai key untuk menentukan kapan cache perlu diperbarui dan tidak.

8. **Gunakan camel case atau snake case untuk penamaan field di dalam request/response body**  
   * **Contoh field dengan camel case:** firstName, orderTotal  
   * **Contoh field dengan snake case:** first\_name, orer\_total  
2. Pilih salah  satu dari case tersebut dan gunakan secara konsisten pada service yang dikembangkan. Pertimbangan pemilihan case dapat didasari oleh bahasa pemrograman yang digunakan oleh backend (misal JS menggunakan camel case, Python menggunakan snake case).

9. **Gunakan nama field yang deskriptif**  
   Gunakan nama yang jelas dan deskriptif. Hindari penyingkatan kecuali untuk yang telah diketahui secara umum (misalnya, id).  
     
10. **Jangan gunakan request body untuk request GET**  
    Beberapa library API backend (seperti FastAPI) memperbolehkan developer untuk mengakses body dari request GET sementara beberapa library request client (seperti Axios) tidak memperbolehkan developer menyertakan body pada request GET. Untuk memastikan kompabilitas antar library, pastikan tidak ada aplikasi yang memproses atau menyertakan body pada request GET.

11. **Struktur JSON response body**  
    Berikut adalah struktur response body yang akan digunakan pada service-service Inergi.  
    * **message**  
      Berisi pesan untuk keperluan debugging atau sebagai user feedback yang ditampilkan melalui service frontend.  
    * **data**  
      Berisi data sesuai dengan fungsi dari API yang dipanggil. Pada request yang gagal, field ini dapat digunakan untuk memberikan informasi tambahan sesuai kebutuhan.  
    * **meta**  
      Berisi metadata dari request.  
      * **uuid**  
        UUID dari service pengirim response. Akan unik untuk setiap replika service (suatu service akan bisa memiliki banyak replika).  
      * **id** (optional, default \= null)  
        ID dari request.  
      * **process\_time\_ns** (optional, default \= null)  
        Durasi pemrosean request dalam nano second.

Contoh response success

```json
{
  "message": "",
  "data": {
    "items": ["..."],
    "total_items": 17,
    "total_pages": 4
  },
  "meta": {
    "uuid": "...",
    "id": "...",
    "process_time_ns": 123456789
  }
}
```

Contoh response failed

```json
{
  "message": "Too many requests",
  "data": {
    "retry_after_seconds": 60,
    "rate_limit_exceed": true
  },
  "meta": {
    "uuid": "...",
    "id": "...",
    "process_time_ns": 123456789
  }
}
```

**Contoh Kasus**  
Referensi:

* Gemini 3.0 Pro (diakses pada 14 Januari 2026\)

Misal terdapat 3 endpoint berikut.

1. Get all/many users  
2. Get one user detail  
3. Get my own detail as a user

Untuk ketiga endpoint tersebut, gunakan endpoint path berikut.

1. GET /users/  
2. GET /users/{user\_id}  
3. GET /users/me

Sistem penamaan yang sama bisa digunakan untuk method lainnya.

# Status Code

Referensi:

* [https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status) (diakses pada 21 Agustus 2025\)

Penggunaan status code yang sesuai dengan peruntukannya dapat membantu developer dalam debugging. Berikut adalah daftar status code yang umumnya dipakai beserta dengan use case masing-masing status code.

## 200 OK

**Definisi** : Permintaan berhasil  
**Use case** :

1. Seluruh request yang berhasil diproses

## 202 Accepted

**Definisi** : Permintaan diterima oleh server, tapi belum dikerjakan.  
**Use case** :

1. Noncommital request, seperti trigger webhook, proses add queue, atau trigger proses lainnya

## 400 Bad Request

**Definisi** : Server tidak dapat memahami permintaan karena sintaks yang tidak valid (misalnya, format JSON yang salah). Jika value valid secara sintaks tapi tidak valid berdasarkan kriteria validitas bisnis, error code yang digunakan adalah 422 Unprocessed Entity.  
**Use case** :

1. User mengirim request body yang seharusnya berupa JSON, tapi tidak bisa diload sebagai JSON object.

## 401 Unauthorized

**Definisi** : Autentikasi diperlukan tetapi gagal atau belum diberikan.  
**Use case** :

1. User mengirimkan request (misal melalui Postman, curl, script Python) tanpa JWT ke endpoint yang memerlukan autentikasi.  
2. JWT yang dikirimkan oleh user tidak valid (tidak terdaftar atau expired).  
3. User mencoba login dengan username atau password yang salah. [Referensi](https://stackoverflow.com/a/32752617%20)

## 403 Forbidden

**Definisi** : Permintaan valid, tetapi server menolak untuk mengotorisasi pengguna (misalnya, user berhasil login tetapi tidak memiliki izin untuk mengakses resource tertentu).  
**Use case** :

1. User tidak memiliki license valid untuk produk X, tapi mencoba mengirimkan request ke produk X dengan JWT yang diperoleh dari produk lain.  
2. User memiliki license produk X dengan balance prepaid 0, tapi mencoba mengirimkan request (beserta JWT) ke endpoint produk X yang menggunakan balance license.  
3. User non-admin mengirimkan request (beserta JWT) ke endpoint yang memerlukan akses admin.

## 404 Not Found

**Definisi** : Server tidak dapat menemukan resource yang diminta (misalnya, URL yang salah).  
**Use case** :

1. User mengirimkan request atas resource yang tidak ada. Misal, user mengirimkan request ke endpoint “/users/{id}” dengan parameter “id” bernilai “123”, sementara “user” yang ada hanyalah user dengan “id”=“1”.  
2. User mengakses endpoint yang tidak didefinisikan di aplikasi. Misal, user mengirimkan request ke endpoint “/products” padahal endpoint yang ada di aplikasi hanyalah “/users”.

## 405 Method Not Allowed

**Definisi** : Service tidak meng-handle method yang dimaksud pada request.  
**Use case** :

1. Misal, user mengirimkan request POST ke endpoint X, tapi service hanya meng-handle method GET, PUT, DELETE untuk endpoint X.

## 411 Length Required

**Definisi** : Header “content-length” diperlukan, tapi tidak terdapat pada request.  
**Use case** :

Error code ini bisa jadi tidak diperlukan jika validasi ukuran file tidak dilakukan dengan menggunakan content-length.

## 413 Content Too Large

**Definisi** : Content-length request terlalu besar.  
**Use case** :

1. User mengirimkan file yang berukuran sangat besar.

Error code ini bisa jadi tidak diperlukan jika validasi ukuran file tidak dilakukan dengan menggunakan content-length.

## 422 Unprocessable Content

**Definisi** : Server memahami tipe konten dari permintaan dan sintaks entitas permintaan sudah benar, tetapi server tidak dapat memprosesnya karena adanya kesalahan semantik.  
**Use case** :

1. Data yang dikirimkan oleh klien (misalnya, melalui form atau body permintaan JSON) memiliki format yang benar secara teknis, tetapi tidak valid dari segi bisnis atau validasi. Contoh:  
   1. Pengguna mencoba membuat akun baru tetapi alamat email yang diberikan tidak memiliki format yang benar (misalnya, tidak ada @).  
   2. Sebuah field yang wajib diisi ternyata kosong.  
   3. Nilai yang dikirimkan tidak sesuai dengan batasan yang ditetapkan (misalnya, umur diisi \-5).  
   4. Pengguna mengirimkan file dengan ekstensi yang tidak sesuai dengan ekspektasi endpoint (misal, mengirimkan file PDF ke endpoint yang meng-handle file gambar PNG/JPEG).  
2. Permintaan gagal karena tidak memenuhi aturan bisnis yang ada. Contoh:  
   1. Pengguna mencoba memesan produk, tetapi stok produk sudah habis.  
   2. Pengguna mencoba mengubah password lama, tetapi password lama yang dimasukkan tidak cocok.

**Handling Pydantic message :**  
Contoh Pydantic model
``` python
from pydantic import BaseModel, Field

class ExtractionRequest(BaseModel):  
    template_id: int = Field(..., ge=1, description="ID dari template yang akan digunakan")  
    image_base64: str = Field(..., description="Gambar dalam format base64")
```

Contoh format response 422 bawaan FastAPI  
``` json
{  
  "detail": [  
    {  
      "loc": [  
        "body",  
        "template_id"  
      ],  
      "msg": "ensure this value is greater than or equal to 1",  
      "type": "value_error.number.not_ge"  
    }  
  ]  
}
```

Cara mengubah format response 422 bawaan FastAPI  
``` python
from fastapi import FastAPI, Request, status  
from fastapi.encoders import jsonable_encoder  
from fastapi.exceptions import RequestValidationError  
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(RequestValidationError)  
async def validation_exception_handler(request: Request, exc: RequestValidationError):  
    error_messages = []  
    for error in exc.errors():  
        # Menyesuaikan pesan error agar lebih mudah dibaca  
        field_name = error.get("loc")[-1]  
        error_type = error.get("type")  
        message = error.get("msg")  
          
        # Contoh kustomisasi berdasarkan tipe error  
        if error_type == "value_error.number.not_ge":  
            custom_msg = f"Field '{field_name}' harus lebih besar atau sama dengan 1."  
            error_messages.append(custom_msg)  
        else:  
            error_messages.append(f"Field '{field_name}': {message}")

    return JSONResponse(  
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,  
        content=jsonable_encoder({  
            "success": False,  
            "message": "Validasi data gagal.",  
            "errors": error_messages,  
            "error_code": "VALIDATION_ERROR"  
        }),  
    )
```

## 500 Internal Server Error

**Definisi** : Kesalahan generik yang tidak dapat ditangani server. Ini sering kali menjadi indikasi adanya *bug* atau masalah internal pada server.  
**Use case** :

## ~~502 Bad Gateway~~

**Definisi** : Server mendapatkan respons error saat mengirimkan request ke server lain untuk memenuhi request user.  
**Use case**: **Tidak digunakan** karena server perantara sebaiknya meneruskan error yang diterimanya dari server lain ke user. Jika server perantara tidak mendapatkan respons sebelum batas timeout, server perantara seharusnya mengembalikan status code 504 Gateway Timeout.

## 503 Service Unavailable

**Definisi** : Server tidak dapat menangani permintaan saat ini, biasanya karena kelebihan beban atau sedang dalam pemeliharaan.  
**Use case** :

## 504 Gateway Timeout

**Definisi** : Server tidak mendapatkan respons sebelum batas timeout ketika mengirimkan request ke server lainnya.  
**Use case** :

1. Service backend (misal FastAPI backend PDF OCR) tidak mendapatkan respons dari service core (misal Tesseract) saat memproses request dari user.

# API Versioning

## URI versioning

Referensi:

* [https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design\#implement-versioning](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design#implement-versioning)  
* [https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/\#h-versioning-our-apis](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/#h-versioning-our-apis) 

Tambahkan v1, v2, dst di dalam endpoint path. Contoh:

```code
https://api.my.com/v1/customers
https://api.my.com/v2/customers
```

## Project directory structure

Referensi:

* [https://softwareengineering.stackexchange.com/questions/278876/what-is-the-correct-project-file-structure-for-a-versioned-rest-api](https://softwareengineering.stackexchange.com/questions/278876/what-is-the-correct-project-file-structure-for-a-versioned-rest-api)

Gunakan struktur direktori seperti berikut.
```text
.
app
├── v1
│   ├── book
│   └── author
└── v2
    └── author
```

Jangan pisahkan direktori seperti berikut.

``` text
.
app
├── book
│   ├── v1
└── author
    ├── v1
    └── v2
```