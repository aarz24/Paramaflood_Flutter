# 📄 PROPOSAL PERANCANGAN IoT — IT FEST 6.0 2026

> **Judul Karya:** ParamaFlood Monitor — Sistem Pemantauan Cuaca dan Peringatan Dini Banjir Berbasis IoT dengan Indikator Mekanis Pintar (ESP-NOW), Prediksi LSTM, Kecerdasan Buatan Gemini 3.6 Flash, dan Aplikasi Mobile Flutter
>
> **Kategori Lomba:** Internet of Things (IoT)
>
> **Sub-Tema:** d. Inovasi AI Berkelanjutan untuk Mengatasi Perubahan Iklim dan Tantangan Lingkungan
>
> **Tim:**
> | No | Nama | NIM | Peran |
> |----|------|-----|-------|
> | 1 | Arya *(Ketua)* | [NIM] | Hardware & Embedded Systems Lead |
> | 2 | Ariel | [NIM] | Frontend UI/UX & Mobile Lead |
> | 3 | Naina | [NIM] | Backend AI & Cloud Integration Lead |
>
> **Perguruan Tinggi:** Universitas Paramadina
>
> **Tahun Kompetisi:** 2026

---

## RINGKASAN EKSEKUTIF

Banjir merenggut ratusan nyawa dan menggusur jutaan warga Indonesia setiap tahun, namun peringatan dini yang ada masih bersifat *reaktif* — alarm baru berbunyi setelah air sudah naik. Di sisi lain, model prediksi *deep learning* terbaik hanya hidup di jurnal ilmiah, terputus dari sensor di lapangan dan dari masyarakat yang membutuhkan informasinya. **ParamaFlood Monitor** hadir untuk menjembatani kesenjangan ini.

ParamaFlood adalah sistem peringatan dini banjir dan pemantauan cuaca terintegrasi *end-to-end* yang menghubungkan empat rantai yang selama ini terputus: ***sensing* → *prediction* → *dissemination* → *action***. Sistem ini menggabungkan perangkat keras IoT *Dual-Node* berbasis ESP32 (menggunakan protokol lokal ESP-NOW) dengan enam modul sensor lingkungan dan sebuah indikator peringatan mekanis (*mechanical alert display*) berbasis putaran servo. Sistem juga didukung oleh model prediksi banjir *Long Short-Term Memory* (LSTM) yang diaugmentasi data prakiraan cuaca numerik, kecerdasan buatan Google Gemini 3.6 Flash untuk analisis berstruktur, serta aplikasi *dashboard* lintas-platform Flutter dengan desain *glassmorphic* premium.

Sistem ini dirancang untuk menjawab tiga *research gap* yang teridentifikasi dalam literatur:

1. **Sensing–Prediction Gap:** Sistem pemantauan banjir IoT yang ada (Loong et al., 2023; Wandi & Ashari, 2023) mengandalkan klasifikasi *threshold* sederhana yang hanya memicu peringatan *setelah* banjir terjadi, tanpa kemampuan prediktif. Model LSTM telah terbukti unggul dalam prediksi banjir (Song et al., 2020; Kratzert et al., 2018) namun hanya divalidasi pada dataset historis offline — belum terintegrasi dengan sensor IoT *real-time*.

2. **Prediction–Dissemination Gap:** Model prediksi *deep learning* menghasilkan luaran probabilistik yang bernilai tinggi, namun literatur belum menghubungkan luaran tersebut ke mekanisme diseminasi peringatan berbasis *push notification* yang *role-based* dan *actionable* (Saputra et al., 2023; Hasibuan et al., 2022).

3. **Hyperlocal Deployment Gap:** Sistem peringatan banjir pemerintah (BPBD) beroperasi pada skala makro jaringan sungai utama, meninggalkan sistem drainase *micro-catchment* di kampus, perumahan, dan kawasan komersial tanpa pemantauan otomatis (Prasetyo et al., 2021).

**Solusi ParamaFlood** menutup ketiga *gap* tersebut melalui:

- **(1) Integrasi LSTM + IoT *real-time*:** Model LSTM menerima data sensor lokal dan data prakiraan cuaca NWP dari Open-Meteo API untuk menghasilkan prediksi kuantitatif ketinggian air pada horizon 1–36 jam ke depan.
- **(2) Pipeline diseminasi cerdas:** Firebase Cloud Messaging (FCM) dengan skema *role-based alerts*, diperkaya analisis kontekstual Google Gemini 2.5 Flash yang menerjemahkan data teknis menjadi narasi *actionable* dalam Bahasa Indonesia.
- **(3) Deployment hyperlocal:** Studi kasus pada kanal drainase kampus Universitas Paramadina (koordinat: -6.315408, 106.906082) sebagai representasi *micro-catchment* perkotaan.

**Keunggulan arsitektural utama** terletak pada dua inovasi: (1) Inovasi Hardware dengan *Dual-Node ESP32 Architecture* menggunakan ESP-NOW untuk komunikasi latensi ultra-rendah tanpa WiFi antara Node Sensor dan Node Aktuator (indikator visual mekanis putar); (2) Pendekatan kecerdasan buatan dua lapis (*Dual-Layer AI*): LSTM sebagai *backbone* prediktif kuantitatif, dan Gemini 3.6 Flash sebagai lapisan kecerdasan diseminasi yang menghasilkan *Structured Card UI* berisi kondisi cuaca, status air, dan rekomendasi mitigasi konkret, serta chatbot interaktif (ParaBot). Seluruh komponen beroperasi di *free tier*, dengan total biaya hardware **Rp1.675.000** — jauh di bawah sistem hidrologi komersial, menjadikan ParamaFlood solusi *monitoring & control* yang cerdas, tangguh, dan siap direplikasi.

---

## BAB I — PENDAHULUAN

### 1.1 Analisis Situasi dan Permasalahan

Indonesia menempati peringkat sebagai salah satu negara paling rawan banjir di dunia. Data Badan Nasional Penanggulangan Bencana (BNPB) menunjukkan bahwa banjir secara konsisten merupakan jenis bencana alam paling sering terjadi di Indonesia, mencakup sekitar 30–40% dari seluruh kejadian bencana yang tercatat setiap tahunnya (BNPB, 2024). Tabel 1.1 merangkum data kejadian banjir dan dampaknya selama periode 2020–2024.

**_Tabel 1.1 — Statistik Bencana Banjir di Indonesia (2020–2024)_**

| Tahun | Total Kejadian Bencana | Kejadian Banjir | % Banjir | Korban Jiwa | Jiwa Terdampak/Mengungsi |
|:-----:|:----------------------:|:---------------:|:--------:|:-----------:|:------------------------:|
| 2020 | ~5.004 | ~1.531 | ~30,6% | 132† | ~3,84 juta |
| 2021 | ~5.402 | ~1.794 | ~33,2% | 337† | ~4,27 juta |
| 2022 | 2.402 | ~857 | ~35,7% | — | — |
| 2023 | ~4.940 | ~1.624 | ~32,9% | — | — |
| 2024 | ~3.472 | 1.109 | ~31,9% | 489‡ | >6 juta‡ |

*Sumber: BNPB — Data Informasi Bencana Indonesia (DIBI), dikompilasi dari bnpb.go.id dan dibi.bnpb.go.id. Keterangan: tanda "~" menunjukkan angka perkiraan dari berbagai sumber BNPB; tanda "—" menunjukkan data belum dipublikasikan secara terpisah per jenis bencana. †Angka korban jiwa khusus bencana banjir. ‡Angka agregat seluruh jenis bencana (data per jenis bencana belum tersedia).*

Tren lima tahun menunjukkan pola yang mengkhawatirkan: meskipun jumlah total kejadian bencana berfluktuasi, **proporsi banjir konsisten di atas 30%**, dan skala dampak kemanusiaan terus meningkat — dari 3,84 juta jiwa terdampak pada 2020 menjadi lebih dari 6 juta pada 2024. Peningkatan ini tidak terlepas dari percepatan urbanisasi, degradasi daerah resapan, dan intensifikasi curah hujan akibat perubahan iklim.

Wilayah metropolitan Jakarta (Jabodetabek) menjadi representasi paling nyata kerentanan ini. Sebagai aglomerasi perkotaan dengan populasi lebih dari 30 juta jiwa, Jakarta mengalami kejadian banjir katastrofik dengan frekuensi dan intensitas yang meningkat. Profil topografi kota — dataran rendah pesisir yang dilintasi 13 sungai mengalir ke utara menuju Laut Jawa — dikombinasikan dengan laju penurunan muka tanah (*land subsidence*) hingga 25 cm per tahun di beberapa distrik utara, menciptakan lingkungan hidrologis di mana bahkan curah hujan moderat 50 mm/hari sudah dapat melampaui kapasitas drainase (Lubis et al., 2022).

Di lingkup yang lebih spesifik, Prasetyo et al. (2021) mendokumentasikan kerentanan kronis sistem drainase *micro-catchment* perkotaan terhadap banjir bandang yang dipicu curah hujan intens berdurasi singkat. Sistem peringatan dini konvensional yang dioperasikan pemerintah (BPBD DKI Jakarta) mengandalkan jaringan *gauge* sungai skala makro dan inspeksi visual manual, meninggalkan sistem drainase lokal di kampus universitas, kompleks perumahan, dan kawasan komersial **tanpa pemantauan otomatis**. Konsekuensinya: ketika banjir terjadi di titik-titik *micro-catchment* yang tidak terpantau, tidak ada mekanisme deteksi otomatis, tidak ada *lead time* prediktif, dan tidak ada jalur notifikasi sistematis kepada pemangku kepentingan.

Ketiadaan kemampuan prediktif ini sangat krusial. Tanpa peringatan dini, tidak ada jendela waktu untuk mengimplementasikan langkah-langkah preventif — memindahkan kendaraan dari area parkir bawah tanah, memasang barier banjir sementara, mengamankan peralatan laboratorium, atau mengaktifkan protokol respons darurat. Perbedaan antara peringatan "setelah air naik" versus "3 jam sebelum air naik" adalah perbedaan antara *damage control* dan *damage prevention*.

### 1.2 Identifikasi Masalah

Berdasarkan analisis situasi di atas, masalah berikut teridentifikasi:

1. Sistem drainase *micro-catchment* perkotaan di kampus-kampus institusional, termasuk kanal di Universitas Paramadina, **tidak memiliki infrastruktur pemantauan *real-time* otomatis** dan secara efektif tidak terlihat oleh jaringan pemantauan banjir skala makro pemerintah (Prasetyo et al., 2021).

2. Sistem pemantauan banjir IoT yang ada mengandalkan mekanisme peringatan berbasis *threshold* sederhana yang hanya memicu notifikasi **setelah** banjir terdeteksi, memberikan **nol** *lead time* prediktif (Wandi & Ashari, 2023; Saputra et al., 2023).

3. Model prediksi banjir *deep learning*, khususnya jaringan LSTM, telah divalidasi secara ekstensif pada dataset historis offline namun **belum diintegrasikan dengan infrastruktur sensor IoT *real-time*** untuk deployment operasional (Song et al., 2020; Kratzert et al., 2018).

4. Aplikasi peringatan banjir mobile yang dikembangkan menggunakan *framework* lintas-platform modern **tidak memiliki kecerdasan prediktif berbasis *machine learning***, membatasi kemampuan peringatannya pada deteksi *threshold* reaktif, bukan *forecasting* proaktif (Saputra et al., 2023; Hasibuan et al., 2022).

5. **Tidak ada sistem tunggal** dalam literatur yang mengintegrasikan akuisisi data IoT multi-sensor, prediksi LSTM yang diaugmentasi data NWP, analisis kontekstual AI generatif, dan diseminasi notifikasi push mobile *role-based* ke dalam satu pipeline peringatan dini *end-to-end* yang dioptimasi untuk lingkungan kampus hyperlocal.

### 1.3 Rumusan Masalah

Berdasarkan identifikasi masalah di atas, pertanyaan penelitian yang dirumuskan adalah:

1. Bagaimana merancang dan mengimplementasikan *edge node* IoT multi-sensor berbasis mikrokontroler ESP32 untuk memantau variabel hidrometeorologi (ketinggian air, intensitas curah hujan, suhu, kelembaban, kecepatan angin, dan intensitas cahaya) secara kontinu di kanal kampus Universitas Paramadina?

2. Bagaimana mengembangkan dan melatih model *deep learning* LSTM untuk memprediksi kenaikan ketinggian air kanal menggunakan data sensor lokal *real-time* yang diaugmentasi dengan data prakiraan cuaca numerik (NWP) dari Open-Meteo API?

3. Bagaimana mengintegrasikan kecerdasan buatan Google Gemini 3.6 Flash untuk menghasilkan output JSON terstruktur berupa kondisi cuaca, tren ketinggian air, rekomendasi mitigasi konkret, serta chatbot interaktif?

4. Bagaimana merancang komunikasi *machine-to-machine* (M2M) menggunakan protokol ESP-NOW antara Node Sensor dan Node Aktuator (Motor Servo) untuk mengontrol indikator status banjir mekanis (memutar pelat warna) di lapangan?

4. Bagaimana mengembangkan aplikasi mobile lintas-platform Flutter dengan *role-based access control* dan Firebase Cloud Messaging (FCM) untuk mendiseminasikan peringatan dini banjir berbasis *machine learning* dan analisis AI kontekstual kepada pemangku kepentingan kampus?

5. Bagaimana performa prediksi model LSTM yang dikembangkan, dievaluasi menggunakan metrik *Root Mean Squared Error* (RMSE), *Mean Absolute Error* (MAE), dan *Nash-Sutcliffe Efficiency* (NSE)?

### 1.4 Tujuan

Sesuai dengan rumusan masalah di atas, tujuan penelitian ini adalah:

1. Merancang dan mengimplementasikan *edge node* IoT multi-sensor menggunakan mikrokontroler ESP32 untuk pemantauan otomatis dan kontinu variabel hidrometeorologi di kanal kampus Universitas Paramadina.

2. Mengembangkan, melatih, dan mengevaluasi model prediksi banjir berbasis LSTM yang memanfaatkan data sensor lokal *real-time* dan data prakiraan cuaca numerik (NWP) eksternal dari Open-Meteo API untuk memprediksi kenaikan ketinggian air kanal pada horizon waktu 1–36 jam ke depan.

3. Mengintegrasikan Google Gemini 3.6 Flash sebagai lapisan kecerdasan untuk menghasilkan visualisasi *Structured Insight Cards* (berisi data ringkas cuaca, air, dan saran mitigasi), laporan harian otomatis, dan chatbot interaktif (ParaBot).

4. Mengembangkan arsitektur indikator responsif (mekanisme Servo memutar pelat karton warna) yang terhubung ke Node Sensor via protokol ESP-NOW, untuk secara otomatis menampilkan warna status bahaya secara fisik pada *enclosure box* saat ambang batas bahaya terlampaui.

4. Mengembangkan aplikasi mobile lintas-platform menggunakan *framework* Flutter dengan *role-based access control* (peran Administrator dan Campus User), Firebase Cloud Messaging (FCM) untuk diseminasi peringatan dini otomatis, dan antarmuka pengguna *glassmorphic* premium.

5. Mengevaluasi akurasi prediksi model LSTM menggunakan metrik regresi dan hidrologi — *Root Mean Squared Error* (RMSE), *Mean Absolute Error* (MAE), dan *Nash-Sutcliffe Efficiency* (NSE) — dengan target NSE > 0,7.

### 1.5 Kontribusi Orisinalitas

ParamaFlood Monitor memberikan empat kontribusi orisinal terhadap *state-of-the-art*:

| No | Kontribusi | Kebaruan terhadap Literatur |
|:--:|------------|----------------------------|
| 1 | **Pipeline *end-to-end* sensing → prediction → dissemination** | Pertama kali mengintegrasikan IoT multi-sensor, LSTM *real-time*, dan notifikasi push *role-based* dalam satu arsitektur |
| 2 | **Arsitektur AI dua lapis (LSTM + Gemini)** | Pertama kali menggabungkan model *deep learning* kuantitatif dengan LLM generatif untuk diseminasi peringatan banjir yang *human-readable* |
| 3 | **Augmentasi data sensor–NWP untuk prediksi banjir** | Memperluas pendekatan Le et al. (2019) dengan data prakiraan NWP *real-time* dari Open-Meteo API sebagai fitur tambahan LSTM |
| 4 | **Deployment hyperlocal di *micro-catchment* kampus** | Pertama kali mendokumentasikan studi kasus pemantauan banjir IoT + LSTM di skala kanal drainase kampus |

### 1.6 Batasan dan Ruang Lingkup

1. Sistem di-*deploy* pada satu lokasi: kanal drainase terbuka yang berdampingan dengan kampus Universitas Paramadina, Cipayung, Jakarta Timur (koordinat: -6.315408, 106.906082). Generalisasi ke lokasi geografis atau tipe *catchment* lain tidak dinilai dalam studi ini.

2. *Edge node* IoT menggunakan mikrokontroler ESP32 DevKit V1 (ESP32-WROOM-32) dipasangkan dengan *expansion board* (shield) yang mengintegrasikan transceiver MAX485 dan ADC ADS1115 pada satu PCB tambahan. Konfigurasi ini berfungsi sebagai pusat pemrosesan, menginterfase enam perangkat sensor:
   - a. Sensor jarak ultrasonik *waterproof* (JSN-SR04T) untuk pengukuran ketinggian air non-kontak;
   - b. *Rain gauge tipping bucket* dengan sensor Hall Effect untuk intensitas curah hujan;
   - c. Sensor suhu dan kelembaban digital kapasitif (DHT22);
   - d. Anemometer *cup* RS485 dengan protokol Modbus RTU untuk kecepatan angin;
   - e. Sensor cahaya ambient fotoelektrik (DFRobot SEN0644) untuk iluminansi;
   - f. ADC SAR 16-bit *on-board* (ADS1115) untuk monitoring tegangan baterai.

3. Data sensor ditransmisikan dari ESP32 ke *cloud* via WiFi (IEEE 802.11 b/g/n) melalui HTTPS. Sistem mengasumsikan konektivitas WiFi kontinu di lokasi *deployment*. *Offline data buffering* dan protokol komunikasi alternatif (LoRa, seluler) tidak diimplementasikan dalam iterasi ini.

4. *Backend cloud* menggunakan arsitektur *microservices* dua layanan: FastAPI (ASGI) untuk ingesti data sensor asinkron berkecepatan tinggi, dan Django (WSGI) untuk REST API aplikasi mobile, autentikasi, dan orkestrasi *background task* via Celery dengan Redis sebagai *message broker*. Firebase Realtime Database dipertahankan untuk sinkronisasi mobile *real-time*.

5. Data sensor dipersistensikan dalam *database time-series* TimescaleDB. Model LSTM dilatih dari data yang dikumpulkan sensor selama periode pengumpulan data lapangan (target: ≥4 minggu, ≥40.000 *records*).

6. Data prakiraan cuaca eksternal bersumber eksklusif dari Open-Meteo API (*free tier*, tanpa API *key*).

7. Aplikasi mobile dikembangkan menggunakan Flutter dan diuji terutama pada perangkat Android. Kompatibilitas iOS diharapkan namun tidak divalidasi secara formal.

### 1.7 Target Pengguna

| Segmen Pengguna | Kebutuhan yang Dijawab | Fitur Utama |
|-----------------|----------------------|-------------|
| **Warga kampus dan area sekitar kanal** | Peringatan dini prediktif (jam, bukan detik) dengan narasi AI yang mudah dipahami | AI Smart Alerts, AI Weather Analysis |
| **Petugas keamanan dan pengelola fasilitas kampus** | Dashboard monitoring *real-time* dan notifikasi push otomatis untuk keputusan evakuasi | Dashboard Sensor, FCM Push Notification |
| **Administrator sistem (peneliti/dosen)** | Akses diagnostik penuh: *battery SoC*, konfigurasi *threshold*, data historis sensor | Settings Panel, RBAC Administrator |
| **Peneliti dan akademisi** | Data historis terstruktur dan platform untuk riset hidrologi-meteorologi lokal | TimescaleDB, Grafik Historis |

### 1.8 Manfaat

#### 1.8.1 Manfaat Praktis

1. **Bagi komunitas kampus:** Sistem menyediakan peringatan dini banjir prediktif yang memberikan *lead time* beberapa jam sebelum banjir terjadi, memungkinkan evakuasi kendaraan, pengamanan peralatan, dan aktivasi protokol darurat — secara fundamental mengubah paradigma respons dari *damage control* menjadi *damage prevention*.

2. **Bagi pengelola fasilitas kampus:** *Dashboard real-time* mengeliminasi kebutuhan inspeksi visual manual, dengan notifikasi push otomatis saat kondisi kritis terdeteksi. Laporan harian AI menyediakan *situational awareness* kontinu tanpa overhead operasional.

3. **Bagi pengembang dan praktisi IoT:** Arsitektur sistem yang modular, seluruhnya menggunakan komponen *open-source* dan layanan cloud *free-tier*, menyediakan *blueprint* yang dapat direplikasi untuk deployment serupa di lokasi *micro-catchment* lainnya dengan total biaya < Rp1.500.000.

4. **Bagi pemerintah daerah (BPBD kelurahan):** Sistem dapat diadopsi sebagai *node* pemantauan tambahan untuk memperluas jangkauan jaringan peringatan dini ke titik-titik *micro-catchment* yang saat ini tidak tercakup oleh infrastruktur monitoring makro.

#### 1.8.2 Manfaat Akademis

1. **Menutup *sensing–prediction gap*:** Penelitian ini memberikan bukti empiris pertama tentang integrasi operasional model *deep learning* LSTM dengan infrastruktur sensor IoT *real-time* dalam satu pipeline peringatan dini banjir.

2. **Menutup *prediction–dissemination gap*:** Menghubungkan luaran prediksi kontinu model LSTM ke notifikasi push mobile *role-based* via FCM, diperkaya narasi AI generatif, memvalidasi pipeline *end-to-end* dari sensing hingga diseminasi.

3. **Menutup *hyperlocal deployment gap*:** Deployment di kanal kampus Universitas Paramadina menyediakan studi kasus terdokumentasi pertama pemantauan banjir IoT + LSTM pada skala *micro-catchment* kampus.

4. **Kontribusi metodologis:** Strategi akuisisi data *dual-source* — menggabungkan data sensor endogen *real-time* dengan data NWP eksogen sebagai *input* LSTM — menyediakan metodologi yang dapat direplikasi dan diperluas oleh peneliti lain.

---

## BAB II — PERANCANGAN SISTEM

### 2.1 Tinjauan Karya Terdahulu

Sebelum merancang arsitektur ParamaFlood, dilakukan tinjauan sistematis terhadap karya terdahulu yang relevan untuk memetakan *state-of-the-art* dan mengidentifikasi celah yang belum terisi. Karya-karya terdahulu diklasifikasikan berdasarkan posisi dalam rantai peringatan dini: **sensing**, **prediction**, atau **dissemination**.

**Kelompok 1 — IoT Sensing Systems:**

Loong et al. (2023) mengembangkan IoT-Based Machine Learning Flood Monitoring System (IM-FMS) yang menggabungkan multi-sensor dengan klasifikasi *machine learning*. Wandi & Ashari (2023) mengimplementasikan monitoring ketinggian air dan curah hujan berbasis IoT menggunakan sensor ultrasonik dan *rain gauge*. Mulyani et al. (2026) membangun sistem monitoring sungai *real-time* dengan ESP32 dan HC-SR04. Ketiga karya ini mendemonstrasikan kelayakan akuisisi data IoT, namun mekanisme peringatannya terbatas pada *threshold* sederhana tanpa prediksi temporal.

**Kelompok 2 — Deep Learning Prediction Models:**

Song et al. (2020) mendemonstrasikan keunggulan LSTM dalam prediksi banjir bandang, mengungguli metode statistik tradisional. Kratzert et al. (2018) memvalidasi LSTM untuk pemodelan *rainfall-runoff*. Le et al. (2019) menunjukkan bahwa augmentasi data sensor dengan data NWP meningkatkan akurasi prediksi secara signifikan. Kim et al. (2025) dan Zhang et al. (2025) masing-masing mengonfirmasi efektivitas LSTM pada data hidrologi *watershed* dan mengembangkan *explainable* LSTM. Seluruh karya ini beroperasi pada dataset historis offline — tidak satupun yang terhubung ke sensor IoT *real-time*.

**Kelompok 3 — Mobile Dissemination Applications:**

Saputra et al. (2023) membangun aplikasi monitoring banjir *real-time* menggunakan Flutter dan Firebase, dan Hasibuan et al. (2022) mendesain aplikasi peringatan banjir mobile lintas-platform. Kedua karya menghasilkan antarmuka yang fungsional, namun tidak menyertakan kecerdasan prediktif berbasis *machine learning* — peringatannya tetap reaktif berbasis *threshold*.

**Sintesis dan Posisi ParamaFlood:**

Tabel 2.1 merangkum perbandingan secara komprehensif. Terlihat jelas bahwa **tidak ada sistem tunggal** yang mengintegrasikan seluruh rantai *sensing → prediction → dissemination* dalam satu pipeline *end-to-end*.

**_Tabel 2.1 — Perbandingan ParamaFlood dengan Karya Terdahulu_**

| Aspek | Loong et al. (2023) [4] | Wandi & Ashari (2023) [5] | Saputra et al. (2023) [10] | Song et al. (2020) [6] | Kim et al. (2025) [20] | **ParamaFlood (Ours)** |
|-------|:-:|:-:|:-:|:-:|:-:|:-:|
| **Platform IoT** | Multi-sensor | Ultrasonic + rain gauge | — | — | — | ESP32 + 6 sensor |
| **Metode Prediksi** | ML klasifikasi | Threshold | — | LSTM (offline) | LSTM (offline) | LSTM + NWP real-time |
| **GenAI / LLM** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Gemini 2.5 Flash |
| **Aplikasi Mobile** | Web dashboard | — | Flutter + Firebase | — | — | Flutter cross-platform |
| **Push Notification** | — | — | Basic | — | — | FCM role-based |
| **Data NWP Eksternal** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ Open-Meteo API |
| **Pipeline End-to-End** | Parsial (sensing+ML) | Parsial (sensing) | Parsial (app) | Parsial (model) | Parsial (model) | ✅ Lengkap |
| **Skala Deployment** | Lab/sungai | Lab | Studi kasus | Dataset historis | Dataset historis | Kampus hyperlocal |

**Kesimpulan tinjauan:** ParamaFlood memposisikan diri sebagai **sistem pertama** yang mengintegrasikan ketiga aspek rantai peringatan dini, ditambah kecerdasan buatan generatif (Gemini 3.6 Flash) sebagai lapisan keempat yang menerjemahkan luaran teknis menjadi informasi yang *actionable* bagi pengguna awam.

### 2.2 Arsitektur Sistem

ParamaFlood mengadopsi arsitektur tiga lapis (*Three-Tier Architecture*) yang memisahkan tanggung jawab antara *sensing*, *processing* (prediction + AI analysis), dan *dissemination*:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ARSITEKTUR PARAMAFLOOD                              │
│                Monitoring & Control (Dual-Node ESP-NOW)                     │
│                                                                             │
│  │                  │    │         +              │    │                  │  │
│  │                  │    │  ┌─────────────────┐  │    │                  │  │
│  │                  │    │  │ FastAPI + Django │  │    │                  │  │
│  │                  │    │  │ + TimescaleDB   │  │    │                  │  │
│  │                  │    │  │ + Celery/Redis  │  │    │                  │  │
│  │                  │    │  └─────────────────┘  │    │                  │  │
│  └──────────────────┘    └───────────────────────┘    └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.1 Arsitektur Kecerdasan Buatan Dua Lapis (Dual-Layer AI)

Diferensiator utama ParamaFlood adalah pendekatan AI dua lapis yang dirancang agar saling melengkapi — bukan saling menggantikan:

| Aspek | LSTM Prediction Layer | Gemini Intelligence Layer |
|-------|----------------------|--------------------------|
| **Fungsi** | Prediksi kuantitatif ketinggian air (t+1h s/d t+36h) | Analisis kontekstual multi-parameter + chatbot |
| **Tipe AI** | Deep Learning (time-series forecasting) | Large Language Model (generative AI) |
| **Input** | Rolling stats sensor + temporal lag + NWP features | 8 parameter sensor + label status + tren + NWP |
| **Output** | Angka prediksi ketinggian air (cm) | Data JSON Terstruktur: Cuaca, Air, Saran, Detail |
| **Evaluasi** | RMSE, MAE, NSE (target: NSE > 0.7) | Relevance scoring (≥ 8/10 respons akurat) |
| **Peran** | **Backbone prediktif** (inti ilmiah) | **Intelligence diseminasi** (pengalaman pengguna) |
| **Keunggulan** | Presisi statistik, *reproducible*, evaluasi metrik | Fleksibilitas bahasa, *reasoning* multi-parameter |
| **Keterbatasan** | Output angka mentah, sulit dipahami awam | Tidak reliable untuk regresi numerik presisi tinggi |

**Rasional desain:** Kombinasi ini mengatasi keterbatasan masing-masing pendekatan secara elegan. LSTM memberikan angka prediksi yang presisi dan secara ilmiah terukur, sementara Gemini menerjemahkan angka tersebut — bersama seluruh konteks sensor — menjadi narasi yang *actionable* bagi pengguna non-teknis.

#### 2.2.2 Alur Data End-to-End

```
                          ┌──→ Firebase Realtime DB (live, overwrite per 1 detik)
                          │         │
ESP32 Sensor ─(HTTPS)─────┤         ├── Stream ke Flutter App (real-time via onValue)
                          │         │        │
                          │         │        ├── Render Dashboard (sensor cards + gauge)
                          │         │        ├── Kirim ke Gemini 3.6 Flash AI → Structured JSON
                          │         │        ├── Render di AI Insight Panel (Visual Mini-Cards)
                          │         │        └── ParaBot AI Chat (konsultasi keselamatan)
                          │         │
                          │         └── ESP-NOW Protocol (Trigger Aktuator Servo)
                          │                  │
                          │                  └── Node Aktuator (ESP32 #2) memutar pelat karton warna (Transparan -> Kuning -> Merah)
                          │         │
                          │         └── Open-Meteo NWP API (per 10 menit)
                          │                  │
                          │                  ├── Perbandingan sensor lokal vs prakiraan internet
                          │                  └── Augmentasi fitur LSTM (forecast features)
                          │
                          └──→ FastAPI Ingestion (history, append per 60 detik — Phase 2)
                                    │
                                    └── TimescaleDB (persistent time-series storage)
                                             │
                                             └── LSTM Inference (setiap 60 detik)
                                                      │
                                                      ├── Prediksi ketinggian air t+1h, t+3h,
                                                      │   t+6h, t+12h, t+24h, t+36h
                                                      └── Threshold breach → Django/Celery → FCM Push
```

### 2.3 Spesifikasi Perangkat Keras (Hardware)

#### 2.3.1 Mikrokontroler

| Komponen | Spesifikasi | Justifikasi Pemilihan |
|----------|-------------|----------------------|
| **Node Sensor (ESP32 #1)** | ESP32-WROOM-32 + Shield MAX485 + ADC ADS1115 | Mengirim data ke Firebase (HTTPS) dan mengirim sinyal bahaya ke Node Aktuator (ESP-NOW) |
| **Node Aktuator (ESP32 #2)** | ESP32-WROOM-32 + Servo Motor | Menerima instruksi ESP-NOW dari Node Sensor secara instan tanpa butuh WiFi internet, khusus memproses animasi gerak servo |
| **Motor Servo** | Servo High Torque (mis. MG996R) / Micro Servo | Aktuator fisik untuk menggerakkan pelat karton warna-warni (transparan, kuning, merah) di balik jendela *box* sistem sebagai indikator bahaya visual |

#### 2.3.2 Modul Sensor

| No | Sensor | Tipe/Model | Parameter | Satuan | Protokol Interface | Fungsi Hidrometeorologi |
|:--:|--------|------------|-----------|:------:|-------------------|------------------------|
| 1 | **Suhu & Kelembaban** | DHT22 (AM2302) | Suhu udara, kelembaban relatif | °C, %RH | Single-Wire Digital (GPIO 13) | Variabel atmosfer lokal; input fitur LSTM; kalkulasi *Heat Index* |
| 2 | **Kecepatan Angin** | Anemometer Cup RS485 | *Wind speed* | m/s | Modbus RTU / RS485 (Addr 0x02) | Indikator badai; input fitur LSTM; klasifikasi skala Beaufort |
| 3 | **Intensitas Cahaya** | DFRobot SEN0644 Ambient Light RS485 | *Illuminance* | Lux | Modbus RTU / RS485 (Addr 0x01) | *Proxy* densitas awan; sinyal *pre-storm darkening* |
| 4 | **Ketinggian Air** | JSN-SR04T Waterproof Ultrasonic | Jarak ke permukaan air | cm | Trigger-Echo TTL (GPIO 5/18) | **Target variable utama** prediksi banjir |
| 5 | **Curah Hujan** | Tipping Bucket Rain Gauge | *Cumulative rainfall* | mm | Hall-Effect Interrupt (GPIO 14) | Fitur prediktif paling berpengaruh (Loong et al., 2023); resolusi **0,70 mm/tip** |
| 6 | **Tegangan Baterai** | ADS1115 16-bit SAR ADC *on-board* + Voltage Divider | Tegangan DC | V | I²C (16-bit, 0.125 mV/bit) | Diagnostik kesehatan sistem; peringatan pemeliharaan |

**Catatan teknis bus RS485:** Anemometer (Modbus address 0x02) dan sensor cahaya SEN0644 (Modbus address 0x01) terhubung ke satu jalur serial diferensial RS485 melalui transceiver MAX485 pada *expansion board* (shield) yang terpasang di atas ESP32 DevKit, dengan kontrol arah pada GPIO 27. Firmware mengimplementasikan *callback* `preTransmission()` dan `postTransmission()` dengan *delay* stabilisasi 50 μs. Kedua sensor beroperasi pada *baud rate* 9.600 bps, *framing* 8N1.

#### 2.3.3 Sistem Daya

| No | Komponen | Spesifikasi | Fungsi |
|:--:|----------|-------------|--------|
| 1 | **Baterai Pack 3S** | 3× 18650 Li-ion (11,1V nominal, ~12,6V penuh) | Sumber daya utama |
| 2 | **LM2596 Buck Converter** | Input 12V → Output 5V | Step-down ke 5V untuk ESP32 dan DHT22 |
| 3 | **Rail 12V langsung** | Dari baterai 3S | Daya langsung untuk periferal RS485 (anemometer, sensor cahaya) |
| 4 | **Solar Panel** | 6W/12V Polycrystalline | *Energy harvesting* surya untuk operasi mandiri jangka panjang |
| 5 | **Solar Charge Controller** | Mode Lithium (Li-ion) | Regulasi pengisian aman ke baterai lithium |
| 6 | **3S BMS Protection Board** | Over-charge/discharge/short protection | Proteksi keselamatan baterai |

**Topologi daya dual-rail:** Baterai 12V 3S Li-Ion sebagai sumber utama, LM2596 *buck converter* menurunkan ke 5V untuk sirkuit logika ESP32 dan sensor DHT22, sementara rail 12V secara langsung menyuplai periferal RS485 yang memerlukan tegangan operasi lebih tinggi.

#### 2.3.4 Struktur Fisik

Seluruh komponen elektronik dirakit dalam **enclosure polycarbonate rating IP65** yang memberikan proteksi terhadap debu dan ingress air dalam kondisi hujan deras. *Enclosure* dipasang pada *tripod stand* yang memastikan: (a) proteksi cuaca, (b) ventilasi udara untuk sensor DHT22, (c) posisi optimal sensor ultrasonik menghadap tegak lurus ke permukaan air, dan (d) portabilitas untuk *re-deployment* ke lokasi alternatif.

### 2.4 Spesifikasi Perangkat Lunak (Software)

#### 2.4.1 Firmware ESP32 (Embedded Software)

| Aspek | Detail |
|-------|--------|
| **Bahasa** | C/C++ (Arduino Framework) |
| **IDE** | PlatformIO (VS Code) |
| **Interval Pembacaan Sensor** | 1 detik (water level, wind, temp/hum, light); akumulasi kontinu (rainfall via interrupt) |
| **Interval Push ke Firebase** | **1 detik** (live data, overwrite ke `/weather_station`) + **10 menit** (history log, append ke `/weather_history`) |
| **Protokol Cloud** | HTTPS REST API ke Firebase Realtime Database |
| **Sinkronisasi Waktu** | NTP (pool.ntp.org), timezone WIB (UTC+7) |
| **Rain Gauge** | Interrupt-driven accumulation dengan software debounce 200ms; resolusi 0,70 mm/tip |
| **Ultrasonic** | Formula: d = (t × 0,034) / 2; timeout 30ms (~5m max); sentinel -1 untuk error |
| **Battery ADC** | ADS1115 *on-board* ch0, gain ±4.096V; divider 100kΩ/33kΩ → Vbatt = VA0 × (133/33) |
| **WiFi Recovery** | Auto-reconnect dengan *exponential backoff* |
| **Fallback** | Nilai sensor terakhir valid digunakan jika pembacaan gagal (NaN protection) |
| **Diagnostik** | Built-in Modbus configuration utility (`#define CONFIGURATION_MODE`) |

**Arsitektur sampling firmware:** Fungsi `sampleAndUpload()` mengeksekusi pembacaan sekuensial enam kanal sensor dalam urutan deterministik — light sensor → wind sensor → DHT22 → rain gauge → ultrasonik → battery voltage — kemudian mengkonstruksi *payload* JSON terstruktur untuk transmisi ke *cloud*.

#### 2.4.2 Aplikasi Mobile Flutter

| Aspek | Detail |
|-------|--------|
| **Framework** | Flutter 3.10+ (Dart 3.0+) |
| **Platform Target** | Android, iOS, Web (responsif) |
| **State Management** | Provider (ChangeNotifier pattern) |
| **Database** | Firebase Realtime Database (streaming *real-time* via `onValue`) |
| **AI Engine** | Google Generative AI package (`google_generative_ai: ^0.4.7`) |
| **Data Cuaca Internet** | Open-Meteo API (gratis, tanpa API key) |
| **Lokasi** | Geolocator + Geocoding (reverse geocode ke nama kota) |
| **Visualisasi** | FL Chart (grafik interaktif), Flutter Animate (animasi premium) |
| **Tipografi** | Google Fonts (Outfit — geometric sans-serif premium) |
| **Tema** | Light Mode *glassmorphic* (*Ice White + Water Blue* palette) dengan palet warna adaptif berbasis status sensor |

**Fitur Aplikasi:**

| No | Fitur | Fase | Deskripsi |
|:--:|-------|:----:|-----------| 
| 1 | **Dashboard Real-time** | ✅ 1 | Hero Panel dengan animasi gelombang air + 7 Sensor Card arc-gauge dengan indikator warna dinamis |
| 2 | **Grafik Historis** | ✅ 1 | Line chart tren interaktif (FL Chart) untuk setiap parameter di layar Riwayat |
| 3 | **Perbandingan Sensor vs Internet** | ✅ 1 | *Side-by-side comparison* data ESP32 vs Open-Meteo NWP (bar chart) |
| 4 | **AI Weather Analysis** | ✅ 1 | *Structured Insight Mini-Cards* dari Gemini 3.6 Flash (Cuaca, Status Air, Rekomendasi) |
| 5 | **AI Flood Risk Assessment** | ✅ 1 | Skor risiko banjir terintegrasi ke dalam UI panel pintar |
| 6 | **ParaBot AI Chat** | ✅ 1 | Chatbot interaktif (floating action button + bottom sheet) untuk konsultasi cuaca dan keselamatan |
| 7 | **AI Daily Report** | ✅ 1 | Ringkasan harian otomatis statistik sensor dan evaluasi keamanan |
| 8 | **AI Smart Alerts** | ✅ 1 | Notifikasi kontekstual saat kondisi bahaya terdeteksi (max 1 per 30 menit) |
| 9 | **Derived Analytics** | ✅ 1 | Heat Index (formula Steadman), Beaufort Scale, *air quality heuristic* |
| 10 | **Splash + Onboarding** | ✅ 1 | Animasi splash screen dan flow onboarding multi-page |
| 11 | **Pengaturan (Settings)** | ✅ 1 | Layar pengaturan: info aplikasi, diagnostik lokasi, kontrol AI, debug panel |
| 12 | **Navigasi Bottom Tab** | ✅ 1 | 3-tab *glassmorphic* bottom nav (Dashboard, Riwayat, Pengaturan) + floating ParaBot button |
| 13 | **LSTM Prediction Display** | 🔧 2 | Prediksi kuantitatif ketinggian air t+1h s/d t+36h dengan visualisasi grafik |
| 14 | **FCM Push Notification** | 🔧 2 | Peringatan dini push *role-based* ke perangkat pengguna |
| 15 | **RBAC Authentication** | 🔧 2 | Firebase Auth; peran Campus User (read-only) dan Administrator (full access) |

#### 2.4.3 Integrasi AI — Arsitektur Dua Lapis

##### Lapis 1: LSTM Prediction Model (Backbone Prediktif)

Model *Long Short-Term Memory* (LSTM) dipilih sebagai *backbone* prediksi banjir berdasarkan tiga pertimbangan:

1. **Arsitektural:** Mekanisme *gating* LSTM (input gate, forget gate, output gate) secara efektif mengatasi *vanishing gradient problem* yang ditemukan pada RNN standar, memungkinkan pembelajaran korelasi temporal jarak jauh yang mencakup beberapa jam hingga hari (Hochreiter & Schmidhuber, 1997).

2. **Empiris:** Literatur terkini secara konsisten menunjukkan keunggulan LSTM atas metode statistik tradisional (ARIMA, regresi linear) dan arsitektur *neural network* yang lebih sederhana (RNN standar, GRU) untuk prediksi banjir pada horizon 1–10 jam (Song et al., 2020; Kim et al., 2025).

3. **Interpretabilitas:** Zhang et al. (2025) mendemonstrasikan *framework explainable* LSTM untuk prediksi banjir, mendukung transparansi model untuk konteks akademis dan regulatori.

**Strategi akuisisi data *dual-source*:**

Model LSTM menerima input dari dua sumber yang saling melengkapi:

- **(a) Data endogen:** Data sensor ESP32 *real-time* — *rolling statistics* (mean, std, min, max) dan *temporal lag features* dari water level, rainfall, temperature, humidity, wind speed, dan light intensity.
- **(b) Data eksogen:** Prakiraan intensitas curah hujan jam-an, suhu, dan kelembaban dari Open-Meteo NWP API — memungkinkan model "melihat ke depan" berdasarkan proyeksi cuaca numerik.

Le et al. (2019) menunjukkan bahwa augmentasi ini memungkinkan eskalasi skor probabilitas banjir lebih awal — sebelum puncak ketinggian air secara fisik terobservasi di titik monitoring.

| Aspek | Detail Implementasi |
|-------|---------------------|
| **Backend Ingestion** | FastAPI (ASGI) — ingesti data sensor asinkron berkecepatan tinggi |
| **Mobile API** | Django (WSGI) + Celery + Redis — REST API, autentikasi, *background task* |
| **Database Historis** | TimescaleDB (PostgreSQL extension untuk time-series) |
| **Input Features** | Sensor readings (rolling stats + temporal lag) + Open-Meteo NWP forecast features |
| **Output** | Prediksi ketinggian air pada horizon t+1h, t+3h, t+6h, t+12h, t+24h, t+36h |
| **Inference Interval** | Setiap 60 detik |
| **Training Data** | Data historis sensor ParamaFlood (target: ≥40.000 records dari ≥4 minggu *field deployment*) |
| **Metrik Evaluasi** | RMSE, MAE, NSE (target: NSE > 0.7) |

##### Lapis 2: Google Gemini 3.6 Flash (Intelligence Diseminasi)

Sementara LSTM menghasilkan prediksi kuantitatif, Google Gemini 3.6 Flash (dengan kemampuan *structured JSON generation*) berfungsi sebagai lapisan kecerdasan diseminasi. Alih-alih mengembalikan paragraf teks panjang yang buruk untuk UI mobile, sistem mem-prompt Gemini untuk me-*return* format JSON kaku berisi field: `risk`, `cuaca`, `air`, `saran`, dan `detail`. Aplikasi Flutter lalu me-render field tersebut menjadi kartu visual (Mini-Cards) yang ringkas dan modern.

**Arsitektur Prompt:**

```
┌─────────────────────────────────────────────────────────┐
│                    PROMPT ENGINEERING                     │
│                                                          │
│  [System Role]                                           │
│    "Kamu adalah sistem AI Evaluator Banjir dan           │
│     Cuaca untuk Paramaflood, sistem peringatan           │
│     dini banjir IoT di Indonesia."                       │
│                                                          │
│  [Data Injection — Real-time]                            │
│    ┌──────────────────────────────────────────┐          │
│    │ 8 parameter sensor ESP32 (real-time)     │          │
│    │ + Label status per parameter             │          │
│    │ + Tren 5 pembacaan terakhir              │          │
│    │ + Akumulasi curah hujan terkini          │          │
│    │ + Data cuaca internet (Open-Meteo)       │          │
│    │ + Heat Index (Steadman formula)          │          │
│    │ + Beaufort Scale classification          │          │
│    └──────────────────────────────────────────┘          │
│                                                          │
│  [Output Format — Structured JSON]                       │
│    {                                                     │
│      "risk": "RENDAH|SEDANG|TINGGI|KRITIS",              │
│      "cuaca": "1 kalimat ringkas + emoji",               │
│      "air": "1 kalimat status air + tren",               │
│      "saran": "1 kalimat rekomendasi konkret",           │
│      "detail": "Paragraf teknis untuk info lebih lanjut" │
│    }                                                     │
│                                                          │
│  [Constraints]                                           │
│    Rate Limit: 45 detik cooldown antar panggilan         │
│    Retry: 1× untuk error transient (503/overload)        │
│    Parsing: Regex fallback jika format tidak diikuti     │
│    Token: ~500 input + ~300 output per call              │
└─────────────────────────────────────────────────────────┘
```

**Mengapa keduanya diperlukan — bukan salah satu saja:**

| Aspek | Threshold If-Else | LLM Saja (Gemini) | **ParamaFlood (LSTM + Gemini)** |
|-------|-------------------|--------------------|---------------------------------|
| Prediksi kuantitatif | ❌ Tidak ada | ❌ Tidak reliable untuk regresi | ✅ LSTM: ketinggian air t+1h…t+36h |
| Lead time prediktif | 0 (reaktif) | Terbatas (estimasi kualitatif) | **Jam** (prediksi kuantitatif) |
| Analisis multi-parameter | Satu per satu | ✅ Simultan | ✅ Simultan (kedua layer) |
| Output untuk warga awam | Kode error teknis | ✅ Narasi kontekstual | ✅ Narasi + prediksi angka |
| Evaluasi ilmiah | N/A | Sulit diukur secara objektif | ✅ RMSE, MAE, NSE |
| Biaya operasional | Rp0 | Rp0 (free tier) | Rp0 (free tier) |

#### 2.4.4 Protokol Komunikasi

| Layer | Protokol | Justifikasi |
|-------|----------|-------------|
| ESP32 #1 ↔ ESP32 #2 | **ESP-NOW** | Transmisi P2P latensi ultra-rendah tanpa router WiFi untuk kontrol servo |
| ESP32 #1 → Firebase | **HTTPS REST API** (TLS 1.2+) | Enkripsi *end-to-end*; mem-_push_ log sensor |
| Flutter ↔ Firebase | **WebSocket** (Firebase SDK) | Streaming *real-time* bidirectional, latensi <100ms |
| Flutter → Gemini | **HTTPS** (gRPC/REST) | API *call* (Model 3.6 Flash) terenkripsi ke Google Cloud |
| Flutter → Open-Meteo | **HTTPS GET** | API publik gratis untuk data NWP; tanpa autentikasi |
| Django → FCM | **Firebase Admin SDK** | *Push notification dispatch* pada *threshold breach* |

#### 2.4.5 Skema Database

| Database | Fungsi | Struktur Data |
|----------|--------|---------------|
| **Firebase RTDB** (`/weather_station`) | Data sensor live (overwrite per 1 detik) | `{temp, hum, wind, light, rain, distance, battery, isOnline, timestamp}` |
| **Firebase RTDB** (`/weather_history`) | Log historis (append per 10 menit) | Array of `WeatherData` objects, ordered by timestamp |
| **TimescaleDB** (Phase 2) | *Persistent storage* untuk training LSTM | Hypertable dengan UTC timestamps; target ≥40.000 records |

#### 2.4.6 FCM Push Notification (Phase 2)

| Aspek | Rencana Implementasi |
|-------|---------------------|
| **Platform** | Firebase Cloud Messaging (FCM) via Django backend |
| **Trigger** | *Flood probability* LSTM > 70% ATAU *water level tier* naik ke Alert/Caution/Danger |
| **Target Latensi** | < 3 detik dari *threshold trigger* ke penerimaan *device* (Saputra et al., 2023) |
| **Skema** | *Role-based alerts*: Campus User (peringatan banjir), Administrator (peringatan banjir + *battery SoC* + diagnostik sensor) |
| **Konten** | Notifikasi AI-*generated* (kombinasi prediksi LSTM + narasi Gemini) |

---

## BAB III — SKEMA IMPLEMENTASI DAN BIAYA

### 3.1 Rencana Pengujian

#### 3.1.1 Pengujian Unit Hardware

| No | Pengujian | Metode | Kriteria Sukses |
|:--:|-----------|--------|-----------------|
| 1 | Akurasi Sensor DHT22 | Bandingkan dengan termometer/higrometer referensi | Δ ≤ ±1°C dan ±3%RH |
| 2 | Akurasi Anemometer | Bandingkan dengan anemometer referensi pada 3 kecepatan | Δ ≤ ±0.5 m/s |
| 3 | Akurasi Ultrasonik JSN-SR04T | Ukur jarak ke permukaan air pada 5 ketinggian berbeda | Δ ≤ ±2 cm |
| 4 | Akurasi Rain Gauge | Tuang volume air terukur, bandingkan pembacaan (0,70 mm/tip) | Δ ≤ ±10% |
| 5 | Ketahanan Baterai | Operasi kontinu tanpa solar, ukur durasi hingga shutdown | ≥ 24 jam (mode *continuous push* 1 detik) |
| 6 | Stabilitas WiFi | Operasi kontinu 24 jam, hitung *uptime* | ≥ 99% |
| 7 | *End-to-End Latency* | Timestamp ESP32 vs timestamp Firebase write | ≤ 3 detik |
| 8 | Reliabilitas Bus RS485 | Operasi kontinu 24 jam, hitung *error rate* | < 1% error |

#### 3.1.2 Pengujian Integrasi End-to-End

| No | Skenario | Metode | Kriteria Sukses |
|:--:|----------|--------|-----------------|
| 1 | **Skenario Normal** | Operasi standar, semua sensor normal | Data tampil *real-time* di app, AI analisis RENDAH |
| 2 | **Skenario Hujan Ringan** | Tuang air ke rain gauge + dekatkan benda ke ultrasonik | AI menaikkan risk ke SEDANG, narasi relevan |
| 3 | **Skenario Banjir** | Simulasi curah hujan tinggi + jarak air <20cm | AI menaikkan risk ke TINGGI/KRITIS, rekomendasi evakuasi |
| 4 | **Skenario Panas Ekstrem** | Panaskan sensor DHT22 hingga >38°C | Heat Index terhitung, *smart alert* terpicu |
| 5 | **Skenario Offline** | Cabut WiFi dari ESP32 | App menampilkan status offline, data terakhir tetap tersedia, auto-reconnect |
| 6 | **ParaBot Chat** | Ajukan 10 pertanyaan berbeda ke chatbot | ≥ 8/10 jawaban relevan dan akurat berdasarkan data sensor |

#### 3.1.3 Evaluasi Model LSTM (Phase 2)

| Metrik | Definisi | Target |
|--------|----------|--------|
| **RMSE** | *Root Mean Squared Error* — penalti lebih besar untuk error besar | Semakin rendah semakin baik |
| **MAE** | *Mean Absolute Error* — rata-rata error absolut | Semakin rendah semakin baik |
| **NSE** | *Nash-Sutcliffe Efficiency* — standar hidrologi; NSE=1 sempurna, NSE<0 lebih buruk dari mean | > 0.7 |
| **RPE** | *Relative Peak Error* — error relatif pada puncak banjir | ≤ ±20% |
| **PTE** | *Peak Time Error* — error estimasi waktu puncak | ≤ ±2 jam |

Model dievaluasi pada *held-out test dataset* menggunakan *sliding window method*, sesuai *framework Qualified Rate* (Song et al., 2020).

#### 3.1.4 Pengujian Lapangan (Outdoor Deployment)

| No | Pengujian | Durasi | Lokasi |
|:--:|-----------|--------|--------|
| 1 | Commissioning awal | 72 jam kontinu | Kanal kampus Universitas Paramadina |
| 2 | *Longitudinal data collection* | ≥ 4 minggu (musim hujan) | Kanal kampus Universitas Paramadina |
| 3 | Performa *solar charging* | 7 hari (siklus *day-night*) | Area terbuka kampus |
| 4 | Ketahanan cuaca (hujan + panas) | Selama periode *data collection* | Kanal kampus Universitas Paramadina |
| 5 | Jangkauan WiFi | Variasi jarak 10–50m dari *router* | *Outdoor* kampus |

### 3.2 Analisis Risiko dan Mitigasi

| No | Risiko | Probabilitas | Dampak | Strategi Mitigasi |
|:--:|--------|:------------:|:------:|------------------|
| 1 | Konektivitas WiFi tidak stabil di lokasi *outdoor* | Sedang | Tinggi | *Exponential backoff reconnect* + NaN protection pada firmware; WiFi extender sebagai *fallback* |
| 2 | Sensor ultrasonik mengalami *false reading* akibat percikan air | Sedang | Sedang | *Mounting* dengan splash guard; *outlier filtering* pada firmware (sentinel -1) |
| 3 | Baterai habis sebelum solar recharge memadai | Rendah | Tinggi | Monitoring *battery SoC* via ADS1115 *on-board* + *smart alert* ke administrator saat tegangan kritis |
| 4 | Data training LSTM tidak cukup (<40.000 records) | Rendah | Tinggi | *Data collection* dimulai sejak Minggu 6; *augmentation* dengan data NWP historis dari Open-Meteo |
| 5 | Kuota *free tier* Google Gemini terlampaui | Rendah | Sedang | Rate limiter 45 detik cooldown; max 1 *smart alert* per 30 menit; monitoring kuota harian |
| 6 | Kerusakan fisik *enclosure* akibat vandalisme atau cuaca ekstrem | Rendah | Tinggi | *Mounting* di area terkontrol kampus; desain *enclosure* yang tidak mencolok; asuransi peralatan |

### 3.3 Rincian Anggaran Biaya (Bill of Materials)

#### 3.3.1 Perangkat Keras

| No | Komponen | Qty | Harga Satuan (Rp) | Total (Rp) |
|:--:|----------|:---:|------------------:|----------:|
| 1 | ESP32 DevKit V1 (ESP32-WROOM-32) + Expansion Board Shield (MAX485 + ADS1115) | 1 | 120.000 | 120.000 |
| 2 | DHT22 (AM2302) Sensor | 1 | 35.000 | 35.000 |
| 3 | Anemometer Cup RS485 Modbus | 1 | 250.000 | 250.000 |
| 4 | DFRobot SEN0644 Ambient Light RS485 | 1 | 180.000 | 180.000 |
| 5 | JSN-SR04T Waterproof Ultrasonic | 1 | 45.000 | 45.000 |
| 6 | Tipping Bucket Rain Gauge | 1 | 150.000 | 150.000 |
| 7 | Solar Panel 6W/12V | 1 | 120.000 | 120.000 |
| 8 | Solar Charge Controller (Li-ion mode) | 1 | 85.000 | 85.000 |
| 9 | 18650 Li-ion Battery Cell (3S pack) | 3 | 35.000 | 105.000 |
| 10 | 3S BMS Protection Board | 1 | 15.000 | 15.000 |
| 11 | LM2596 Buck Converter (12V→5V) | 1 | 20.000 | 20.000 |
| 12 | IP65 Polycarbonate Enclosure + Tripod | 1 | 200.000 | 200.000 |
| 13 | Kabel, konektor, PCB, solder, U.FL antenna | 1 set | 100.000 | 100.000 |
| | **Subtotal Hardware** | | | **Rp1.425.000** |

#### 3.3.2 Perangkat Lunak dan Layanan Cloud

| No | Komponen | Biaya | Keterangan |
|:--:|----------|:-----:|------------|
| 1 | Flutter SDK | Gratis | Open source (Google) |
| 2 | PlatformIO IDE | Gratis | Open source |
| 3 | Firebase Realtime DB | Gratis | Spark Plan (1GB storage, 10GB/bulan transfer) |
| 4 | Google Gemini 2.5 Flash API | Gratis | Free Tier (1.500 request/hari) |
| 5 | Open-Meteo Weather API | Gratis | Open source, tanpa API key |
| 6 | TimescaleDB | Gratis | Open source (self-hosted atau Railway free tier) |
| 7 | FastAPI + Django + Celery + Redis | Gratis | Open source |
| 8 | GitHub Repository | Gratis | Hosting kode sumber |
| | **Subtotal Software** | | **Rp0** |

#### 3.3.3 Total Biaya

| Kategori | Biaya |
|----------|------:|
| Perangkat Keras | Rp1.425.000 |
| Perangkat Lunak & Cloud | Rp0 |
| **TOTAL** | **Rp1.425.000** |

> **Analisis biaya-manfaat:** Total biaya produksi purwarupa ParamaFlood adalah **Rp1.425.000** — kurang dari 1/100 harga stasiun cuaca otomatis komersial (AWS) yang berkisar Rp150–500 juta per unit. Seluruh layanan cloud dan AI beroperasi di *free tier* tanpa biaya bulanan. Dengan asumsi deployment di 100 titik *micro-catchment* di DKI Jakarta, total biaya infrastruktur akan ~Rp142,5 juta — masih jauh di bawah harga satu unit AWS komersial, namun menghasilkan jaringan pemantauan *hyperlocal* yang jauh lebih granular.

### 3.4 Jadwal Pelaksanaan

**_Tabel 3.4 — Timeline Pengerjaan ParamaFlood (12 Minggu)_**

| Fase | Kegiatan | Durasi | Minggu | PIC |
|:----:|----------|:------:|:------:|:---:|
| 1 | Perancangan sistem & pengadaan komponen | 2 minggu | 1–2 | Tim |
| 2 | Assembly hardware, wiring, & firmware ESP32 | 2 minggu | 3–4 | Arya |
| 3 | Pengembangan aplikasi Flutter (Phase 1: Dashboard, AI Panel, ParaBot) | 3 minggu | 3–5 | Ariel |
| 4 | Setup backend cloud (FastAPI + TimescaleDB + Django/Celery) | 2 minggu | 4–5 | Naina |
| 5 | Deployment lapangan & pengumpulan data sensor (≥40.000 records) | 4 minggu | 6–9 | Arya |
| 6 | Integrasi Gemini 2.5 Flash AI + ParaBot ke aplikasi | 2 minggu | 6–7 | Ariel & Naina |
| 7 | Training & evaluasi model LSTM (target NSE > 0.7) | 2 minggu | 9–10 | Naina |
| 8 | Integrasi LSTM prediction display + FCM push notification (Phase 2) | 2 minggu | 10–11 | Tim |
| 9 | Pengujian end-to-end & evaluasi metrik (RMSE, MAE, NSE) | 1 minggu | 11 | Tim |
| 10 | Dokumentasi, proposal final, & video demo | 1 minggu | 12 | Tim |

> **Catatan:** Fase 2–3 dan 4 berjalan paralel untuk efisiensi waktu. Fase 5 (*data collection*) merupakan fase terpanjang karena menentukan kualitas *training data* LSTM — minimal 40.000 records (≈28 hari × 1.440 records/hari pada interval ingesti FastAPI 60 detik). Data historis Firebase (`/weather_history`) dicatat per 10 menit untuk keperluan dashboard, sementara FastAPI (Phase 2) mengingesti per 60 detik untuk granularitas training LSTM yang lebih tinggi.

---

## DAFTAR PUSTAKA

*(Format IEEE)*

[1] Badan Nasional Penanggulangan Bencana (BNPB), "Data Informasi Bencana Indonesia (DIBI) Tahun 2020–2024," Jakarta, Indonesia, 2024. [Online]. Available: https://dibi.bnpb.go.id

[2] S. W. Lubis et al., "Record-breaking precipitation in Indonesia's capital of Jakarta in early January 2020 linked to the northerly surge, equatorial waves, and MJO," *Geophysical Research Letters*, vol. 49, no. 22, Art. no. e2022GL101513, 2022, doi: 10.1029/2022GL101513.

[3] A. Prasetyo et al., "Vulnerability analysis of urban micro-catchment drainage systems to high-intensity rainfall," *Journal of Urban Hydrology*, 2021.

[4] C. Y. Loong et al., "IoT-Based Machine Learning Flood Monitoring System (IM-FMS)," *IEEE Access*, vol. 11, 2023.

[5] I. A. Wandi and A. Ashari, "Monitoring ketinggian air dan curah hujan dalam early warning system bencana banjir berbasis IoT," *IJEIS (Indonesian Journal of Electronics and Instrumentation Systems)*, vol. 13, no. 1, pp. 101–110, 2023, doi: 10.22146/ijeis.83569.

[6] T. Song et al., "Flash Flood Forecasting Based on Long Short-Term Memory Networks," *Water*, vol. 12, no. 1, 2020.

[7] X. H. Le, H. V. Ho, G. Lee, and S. Jung, "Application of long short-term memory (LSTM) neural network for flood forecasting," *Water*, vol. 11, no. 7, p. 1387, 2019, doi: 10.3390/w11071387.

[8] F. Kratzert, D. Klotz, C. Brenner, K. Schulz, and M. Herrnegger, "Rainfall-runoff modelling using Long Short-Term Memory (LSTM) networks," *Hydrol. Earth Syst. Sci.*, vol. 22, no. 11, pp. 6005–6022, 2018.

[9] S. Hochreiter and J. Schmidhuber, "Long short-term memory," *Neural Computation*, vol. 9, no. 8, pp. 1735–1780, 1997, doi: 10.1162/neco.1997.9.8.1735.

[10] R. Saputra, I. Permana, and K. Wijaya, "Real-time flood monitoring mobile application using Flutter and Firebase: A case study in West Java," *Journal of Computer Science and Technology*, vol. 14, no. 2, pp. 88–97, 2023.

[11] M. A. Hasibuan et al., "Design and implementation of a mobile flood warning application using modern cross-platform frameworks," *Int. J. Disaster Risk Reduct.*, 2022.

[12] Espressif Systems, "ESP32 series datasheet," version 4.4, 2023. [Online]. Available: https://www.espressif.com/documentation

[13] Google LLC, "Flutter: UI toolkit for building natively compiled applications," 2023. [Online]. Available: https://flutter.dev

[14] Google LLC, "Firebase Cloud Messaging documentation," 2024. [Online]. Available: https://firebase.google.com/docs/cloud-messaging

[15] Google LLC, "Gemini API Documentation — Generative AI for Developers," 2025. [Online]. Available: https://ai.google.dev/

[16] Google DeepMind, "Gemini 2.5 Flash — Technical Report and Model Card," 2025. Model: `gemini-2.5-flash`, context window: 1,048,576 tokens, multimodal (text+image), optimized for low-latency applications. Free tier: 1,500 requests/day (RPD), 15 RPM, 1M TPM.

[17] P. Zippenfenig, "Open-Meteo.com weather API," Zenodo, 2023, doi: 10.5281/ZENODO.7970649.

[18] Timescale Inc., "TimescaleDB: Open-source time-series database," 2024. [Online]. Available: https://github.com/timescale/timescaledb

[19] A. Mulyani, D. Kurniadi, and R. E. Saputra, "IoT-based real-time river monitoring and early flood warning using ESP32 and HC-SR04," *Journal of Novel Engineering Science and Technology*, vol. 5, no. 1, pp. 55–62, 2026, doi: 10.56741/jnest.v5i01.1252.

[20] D. Kim et al., "Prediction of flood level using LSTM and watershed hydrological data," *Journal of Flood Risk Management*, 2025, doi: 10.1111/jfr3.70123.

[21] Z. Zhang, D. Wang, Y. Mei, J. Zhu, and X. Xiao, "Developing an explainable deep learning module based on the LSTM framework for flood prediction," *Frontiers in Water*, vol. 7, p. 1562842, 2025, doi: 10.3389/frwa.2025.1562842.

---

## LAMPIRAN

*(Sertakan item-item berikut saat pengumpulan final)*

- **Lampiran A:** Foto purwarupa hardware — ESP32 + 6 sensor assembly dalam enclosure IP65
- **Lampiran B:** Foto field deployment setup di kanal kampus Universitas Paramadina
- **Lampiran C:** Screenshot aplikasi Flutter — Dashboard, AI Panel, ParaBot Chat, Grafik Historis
- **Lampiran D:** Diagram arsitektur sistem end-to-end (Three-Tier Architecture + Dual-Layer AI)
- **Lampiran E:** Skematik rangkaian elektronik (wiring diagram, dual-rail power topology)
- **Lampiran F:** Source code Arduino (ESP32 firmware — PlatformIO project)
- **Lampiran G:** Link GitHub Repository
- **Lampiran H:** Tabel perbandingan karya terdahulu versi lengkap (ringkasan: lihat Tabel 2.1 pada BAB II)

---

> **Catatan untuk Tim:**
> 1. Ganti semua `[NIM]` dengan NIM asli masing-masing anggota.
> 2. Masukkan logo Universitas Paramadina di halaman cover dan foto tim.
> 3. Sertakan screenshot aplikasi Flutter (Dashboard, AI Panel, ParaBot Chat, Grafik Historis) sebagai Lampiran C.
> 4. Format final: Times New Roman 12pt, spasi 1.5, margin 3-4-3-3 cm, kertas A4.
> 5. Harga komponen mungkin perlu disesuaikan dengan harga aktual saat pembelian.
> 6. Konversi dokumen ini ke format Word (.docx) untuk submission final.
> 7. **Differensiator kompetisi:** Tekankan bahwa ParamaFlood adalah satu-satunya sistem yang mengintegrasikan *Dual-Layer AI* (LSTM + Gemini) dengan biaya < Rp1.5 juta — ini adalah *unique selling point* terkuat untuk penjurian IT Fest.
