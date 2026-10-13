# Tác động của Bất định Chính sách Kinh tế Toàn cầu đến Biến động Thị trường Chứng khoán Đông Nam Á

Phân tích thực nghiệm bằng R: GARCH-MIDAS và Wavelet Coherence. Dữ liệu 5 thị trường
ĐNÁ (Indonesia, Malaysia, Philippines, Thái Lan, Việt Nam), 2014–2024, tần suất ngày.

## Mục tiêu

Kiểm tra mối quan hệ giữa chỉ số GEPU (Global Economic Policy Uncertainty) và biến động
thị trường chứng khoán ĐNÁ: GEPU có lan truyền vào biến động không, ở khung thời gian nào,
và có dự báo biến động tốt hơn realized volatility (RV) không.

## Phương pháp

- **Wavelet Coherence:** đo đồng chuyển động GEPU–lợi suất theo cả thời gian và tần suất,
  xác định biến nào dẫn (lead-lag).
- **GARCH-MIDAS:** mô hình biến động tần suất hỗn hợp, nối GEPU (tháng) với lợi suất (ngày),
  tách biến động thành thành phần ngắn hạn và dài hạn.
- **Diebold-Mariano test:** so độ chính xác dự báo giữa mô hình GEPU và mô hình RV.


Nghiên cứu kết hợp hai cách tiếp cận bổ sung cho nhau: **Wavelet Coherence** để xác định
quan hệ đồng biến động và dẫn–trễ giữa GEPU và lợi suất theo miền thời gian–tần số, và
**GARCH-MIDAS** để tích hợp dữ liệu tài chính tần suất cao (ngày) với bất định chính sách
tần suất thấp (tháng), tách biến động thành thành phần ngắn hạn và dài hạn.

### 1. Wavelet Coherence

Mức độ tương quan bình phương giữa chuỗi GEPU và lợi suất $r$ tại vị trí (time) $a$ và thang (scale) $b$:

```math
R^2(a,b) = \frac{\left| S\!\left(b^{-1} W_{gepu,\,r}(a,b)\right)\right|^2}
{S\!\left(b^{-1}\,|W_{gepu}(a,b)|^2\right)\; S\!\left(b^{-1}\,|W_{r}(a,b)|^2\right)}
```

trong đó $W_{gepu,r}$ là phổ chéo (cross-wavelet), $W_{gepu}$ và $W_r$ là biến đổi wavelet
liên tục của từng chuỗi, và $S(\cdot)$ là hàm làm mượt. $R^2(a,b)\in[0,1]$ đo mức đồng
biến động theo từng tần số và thời điểm.

Quan hệ pha (phase difference) xác định chiều dẫn–trễ:

```math
\phi_{gepu,\,r}(a,b) = \tan^{-1}\!\left(
\frac{\Im\{S(b^{-1} W_{gepu,r}(a,b))\}}{\Re\{S(b^{-1} W_{gepu,r}(a,b))\}}\right)
```

Mũi tên sang phải: đồng pha (in-phase, tương quan dương); sang trái: ngược pha. Hướng mũi
tên cho biết GEPU dẫn hay lợi suất dẫn tại dải tần số đó.

### 2. GARCH-MIDAS

Lợi suất ngày $i$ của tháng $t$ được phân rã thành thành phần ngắn hạn $g_{i,t}$ và dài
hạn $\tau_t$:

```math
r_{i,t} = \mu + \sqrt{\tau_t \, g_{i,t}}\;\varepsilon_{i,t},
\qquad \varepsilon_{i,t}\mid \Phi_{i-1,t} \sim N(0,1)
```

**Thành phần ngắn hạn** là một quá trình GARCH(1,1) chuẩn hóa theo $\tau_t$:

```math
g_{i,t} = (1-\alpha-\beta) + \alpha\,\frac{(r_{i-1,t}-\mu)^2}{\tau_t} + \beta\,g_{i-1,t}
```

**Thành phần dài hạn** là trung bình MIDAS có trọng số của $K$ trễ của biến tần suất thấp
$X$ (với $X$ lần lượt là RV hoặc GEPU, cho hai mô hình so sánh):

```math
\tau_t = \exp\!\left( m + \theta \sum_{k=1}^{K} \delta_k(\omega_1,\omega_2)\, X_{t-k} \right)
```

Trọng số MIDAS dùng hàm Beta (ràng buộc $\omega_1 = 1$, trọng số giảm dần theo độ trễ):

```math
\delta_k(\omega_1,\omega_2) =
\frac{(k/K)^{\omega_1-1}\,(1-k/K)^{\omega_2-1}}
{\sum_{j=1}^{K}(j/K)^{\omega_1-1}\,(1-j/K)^{\omega_2-1}}
```

Realized Volatility theo tháng (năm hóa) được tính từ lợi suất ngày:

```math
RV_t = 100\sqrt{\frac{252}{N_t}\sum_{i=1}^{N_t} r_{i,t}^2}
```

Hai biến được ước lượng: **GARCH-MIDAS-RV** ($X = RV$) và **GARCH-MIDAS-GEPU**
($X = GEPU$), với $K = 73$ tháng, phân phối chuẩn, trọng số Beta; 180 quan sát cuối được
giữ lại để đánh giá dự báo ngoài mẫu.

### 3. Kiểm định Diebold-Mariano

So sánh độ chính xác dự báo của hai mô hình dựa trên chênh lệch hàm tổn thất của sai số
dự báo. Với proxy phương sai là bình phương lợi suất, sai số của mỗi mô hình là
$e_{\cdot,t} = r_t^2 - \widehat{\sigma}^2_{\cdot,t}$, và chênh lệch tổn thất (bình phương):

```math
d_t = e_{gepu,\,t}^2 - e_{rv,\,t}^2,
\qquad \bar d = \frac{1}{T}\sum_{t=1}^{T} d_t
```

Thống kê DM tiệm cận chuẩn:

```math
DM = \frac{\bar d}{\sqrt{\widehat{V}(\bar d)\,/\,T}} \;\sim\; N(0,1)
```

Với mẫu hữu hạn, áp dụng hiệu chỉnh Harvey–Leybourne–Newbold (1997):

```math
DM^{*} = \sqrt{\frac{T + 1 - 2h + T^{-1} h(h-1)}{T}}\; DM
```

Giả thuyết $H_0: E(d_t)=0$ (hai mô hình dự báo ngang nhau). Thống kê **âm** có ý nghĩa →
GARCH-MIDAS-GEPU chính xác hơn; **dương** có ý nghĩa → GARCH-MIDAS-RV chính xác hơn.

## Kết quả chính

### 1. Thống kê mô tả
Lợi suất log theo ngày (2014–2024, n = 4.018) của cả 5 thị trường đều có trung bình
gần 0, lệch trái (−0,27 đến −1,92) và nhọn mạnh (excess kurtosis 8,0–36,6), đuôi dày,
phi chuẩn (phân phối), đặc trưng của thị trường mới nổi. Ljung-Box trên bình phương lợi suất và
ARCH(10) có ý nghĩa ở mức 1% cho mọi chuỗi, xác nhận hiện tượng volatility clustering và hiệu ứng ARCH là cơ sở để dùng lớp mô hình (G)ARCH. Thống kê
KPSS nhỏ và không có ý nghĩa → mọi chuỗi lợi suất đều dừng. GEPU (theo tháng, n = 216)
lệch phải (0,82), gần mesokurtic, dai dẳng và dừng.
[Thống kê mô tả](result/tables/descriptive_stats.csv) 

### 2. Tương quan chéo thị trường
Toàn bộ tương quan Pearson theo cặp đều dương và có ý nghĩa ở mức 1%. Indonesia,
Malaysia, Philippines và Thái Lan tạo thành một cụm (0,34–0,41), trong khi Việt Nam
tương quan thấp nhất với mọi thị trường (0,19–0,26) cho thấy mức độ phân mảnh tương
đối cao, nhất quán với độ mở tài khoản vốn thấp hơn của Việt Nam.
[Ma trận tương quan](result/tables/correlation.csv)

### 3. Wavelet Coherence (H1, H2)
Độ gắn kết (coherence) giữa GEPU và lợi suất từng thị trường tập trung ở dải tần số
trung–dài hạn (scale ≈ 64–256, tức chu kỳ vài tháng đến vài năm) và mạnh lên quanh
2019–2023 (COVID-19 và các cú sốc kế tiếp). Các vùng có ý nghĩa chủ yếu đồng pha
(in-phase). Ở dải ngắn hạn (0–16), coherence chỉ xuất hiện rải rác, không liên tục.
Kết quả ủng hộ mối quan hệ lan tỏa mạnh nhất ở trung–dài hạn (H1) và quan hệ dẫn–trễ
ngắn hạn mang tính gián đoạn hơn là dai dẳng (H2). 

**Lưu ý:** *Các dải ở tần số thấp nhất nằm
ngoài vùng ảnh hưởng tin cậy Cone of Influence (COI - đường viền nón màu trắng trên ảnh kết quả) nên không diễn giải.*

![Wavelet Coherence: GEPU và Indonesia](result/GEPU%20-%20INA.png)
![Wavelet Coherence: GEPU và Malaysia](result/GEPU%20-%20MAS.png)
![Wavelet Coherence: GEPU và Philippines](result/GEPU%20-%20PHI.png)
![Wavelet Coherence: GEPU và Thái Lan](result/GEPU%20-%20THA.png)
![Wavelet Coherence: GEPU và Việt Nam](result/GEPU%20-%20VIE.png)

### 4. Ước lượng GARCH-MIDAS
Động học ngắn hạn mạnh và nhất quán ở cả hai ước lượng: α (ARCH) 0,04–0,06 và β (GARCH)
0,87–0,96, đều có ý nghĩa 1%, với α+β < 1 (phương sai có điều kiện dừng, độ dai dẳng
cao). Tuy nhiên, hệ số tải dài hạn θ (MIDAS) chỉ có ý nghĩa ở một số ít thị trường
với RV là Indonesia (+) và Philippines (−); với GEPU chủ yếu là Việt Nam cho thấy cả
realized volatility lẫn GEPU đều không có tác động dài hạn in-sample bền vững lên biến
động ở phần lớn thị trường trong mẫu này.
[GARCH-MIDAS-RV](result/tables/garch_midas_rv.csv)
[GARCH-MIDAS-GEPU](result/tables/garch_midas_gepu.csv)

### 5. So sánh dự báo - Kiểm định Diebold-Mariano (H3)
Kiểm định DM so sánh độ chính xác dự báo ngoài mẫu (180 ngày) của mô hình
GARCH-MIDAS-GEPU với mô hình chuẩn GARCH-MIDAS-RV, tính trên sai số dự báo phương sai
(squared-return). Quy ước: thống kê **âm** ủng hộ GEPU, **dương** ủng hộ RV.

[kiểm định DM](result/tables/dm_test.csv)
| Thị trường | h = 10 | h = 30 | h = 60 | h = 180 |
|---|---|---|---|---|
| INA | +13,42*** | +3,91*** | −0,03 | −0,28 |
| MAS | +8,31*** | −0,33 | −1,58 | −0,76 |
| PHI | 0,64 | 1,52 | 0,90 | 0,36 |
| THA | 1,46 | 0,53 | −0,57 | 1,32 |
| VIE | +7,81*** | 1,33 | 0,28 | +7,35*** |

Mọi thống kê có ý nghĩa đều **dương**: mô hình dựa trên RV dự báo tốt ngang bằng hoặc tốt hơn đáng kể so với mô hình dựa trên GEPU ở horizon ngắn (Indonesia, Malaysia,
Việt Nam ở h = 10, h = 180). Không thị trường nào cho thấy GEPU vượt
trội có ý nghĩa ở bất kỳ horizon nào; ở horizon trung và dài hạn, hai mô hình không phân
biệt được về mặt thống kê với phần lớn thị trường. Như vậy, **GEPU không cho thấy khả
năng dự báo biến động vượt trội so với realized volatility** ở các thị trường này, RV mới là bên trội ở ngắn hạn.

### Ghi chú phương pháp
- Mô hình ước lượng bằng `rumidas` (GARCH-MIDAS, phân phối chuẩn, trọng số Beta,
  K = 73 tháng, giữ 180 ngày ngoài mẫu).
- Kiểm định DM (`forecast::dm.test`, hiệu chỉnh Harvey-Leybourne-Newbold) chạy trên sai
  số dự báo so với proxy phương sai là bình phương lợi suất. Vì tập đánh giá là một
  đường dự báo đơn cho mỗi horizon, dùng h = 1 (hiệu chỉnh theo horizon không định danh
  được trên một đường dài h). Do đó khác biệt độ chính xác ở dài hạn mang tính gợi ý
  hơn là khẳng định.

## Cấu trúc repo

```
.
|-- Data.xlsx
|-- R
    |-- descriptive_correl.R
    |-- Wavelet.R
    |-- garch_midas.R
`-- result
    |-- GEPU - INA.png
    |-- GEPU - MAS.png
    |-- GEPU - PHI.png
    |-- GEPU - THA.png
    |-- GEPU - VIE.png
    `-- table
        |-- descriptive_stats.csv
        |-- correlation.csv
        |-- garch_midas_rv.csv
        |-- garch_midas_gepu.csv
        |-- dm_test.csv

```

## Dữ liệu

| Chuỗi | Thị trường | Tần suất | Nguồn |
|---|---|---|---|
| INA, MAS, PHI, THA | JKSE, KLCI, PSEi, SETI | Ngày | Yahoo Finance (stockdex) |
| VIE | VN-Index | Ngày | Investing.com |
| GEPU | Chỉ số GEPU | Tháng | Baker et al. (2016) |

Xử lý missing bằng LOCF. Nguồn mở.

## Cách chạy

1. Mở `Data.xlsx` cùng thư mục với script.
2. Chạy lần lượt: `descriptive_correl.R` → `garch_midas.R` → `Wavelet.R`.

Thư viện R: readxl, xts, rumidas, biwavelet, forecast, FinTS, tseries, openxlsx.
