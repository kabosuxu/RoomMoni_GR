=begin
2019/07/23 研究室開錠確認システム
【機能】
　研究室の開錠状況をSNS (LINE)で通知
【原理】
　照度センサ (GL5529) で得た値をGR-CITRUSで処理し
　IFTTT経由でLINE Notifyへデータを渡しユーザへ通知
=end

# シリアル通信初期化
Usb = Serial.new(0, 115200)             ##Usbクラスを生成 (boud rate : 115200)

# WiFiのSSID、パスワード設定
SSID = ""
Passwd = ""

#ESP8266を一度停止させる(リセットと同じ)
WiFiEN = 5                              #WiFiのEN:LOWでDisable
digitalWrite(WiFiEN, 0)                 #LOW:Disable
delay 500                       
digitalWrite(WiFiEN, 1)                 #Enable

#エラー処理
if (System.useWiFi () == 0) then
    Usb.println "WiFi Card can't use."
    System.exit()
end

#01 WiFi接続
Usb.println "WiFi Ready"
Usb.println WiFi.disconnect
Usb.println WiFi.setMode 3              #Station-Mode & SoftAPI-Mode
Usb.println "Connecting AP"
Usb.println WiFi.connect(SSID, Passwd)
Usb.println WiFi.ipconfig               #IPアドレスとMACアドレスを表示
Usb.println "WiFi multiConnect Set"     #接続するAPの”SSID" と "PASSWORD"
Usb.println WiFi.multiConnect 1

#02:定義部
#Header部の生成
header= [ "User-Agent gr-citrus", "Accept: application/json", "Content-type: application/json"]

#変数定義
initial_state =analogRead (17)           #初期照度を格納する変数 "initial_state"
dela 1000                                #1秒待つ
judge = true                             #開錠判定の2値変数 " judge "

#03:以下電源が落ちるまで動作
loop do
    #03-01 研究室の現時点での状況を確認する
    pinMode(17, 0)                                      #17番ピンをインプットピンに設定
    analogReference(2)                                  #analog値の設定
    current_state = (initial_state analogRead (17)).abs #現時点での照度を表す変数"current_state"
    #usb.println(current_state.to_s)
    
    #03-02-a: 研究室の明かりがきえたとき施錠メッセージ文を格納 if(judge == true)
    if(judge == true)
        x="研究室が施錠されました"
    end
    #03-02-b: 研究室の明かりがついたとき開鍵メッセージ文を格納 if(judge == false)
    if(judge == false)
        x="研究室が開錠されました"
    end
    #03-03:照度に一定の変化が出たとき body部生成+メッセージ送信
    if(current_state>200)
        judge ^= true
        y = current_state
        z = ""
        body='{"value":"' +x.to_s+ '","value2":"' +y.to_s+ '","value3":"' +z.to_s+ '"}'
        Usb.println WiFi.httpPost("maker.ifttt.com/trigger/labstate_01/with/key/cW14- CF_xqFLAjUwVR0JmT", header, body).to_s
    end
    #03-04初期值更新
    initial_state = analogRead(17)
    delay 1000
end
#ループ抜けたら (電源切れないから基本抜けない) Wi-Fiを切る。
Usb.println "WiFi disconnect"
Usb.println WiFi.disconnect