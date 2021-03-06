//--- Program Properties ---
#property copyright "Copyright 2018, Keisuke Iwabuchi"
#property strict


//--- Macro substitution ---
#define OPEN_POS 6
#define ALL_POS  7
#define PEND_POS 8
#define RETRY_INTERVAL 1000 // msec
#define RETRY_TIME_LIMIT 5000 // msec


//--- Enumerations ---
/**
 * 取引方向
 */
enum TRADE_SIGNAL
{
    BUY_SIGNAL = 1,
    SELL_SIGNAL = -1,
    NO_SIGNAL = 0
};



/**
 * サマータイムのタイプ
 */
enum SUMMER_TIME_MODE
{
    MODE_NONE = 0, // サマータイム無し
    MODE_EURO = 1, // 欧州
    MODE_USA = 2 // 米国
};


//--- Date and Time ---
/**
 *  取引可能曜日フィルター
 * 
 * @param arr  曜日ごとのフィルターON/OFFの配列 true:取引する, false:しない
 *
 * @return  true: 取引可能, false: 取引不可能
 */
bool DayOfWeekFilter(bool &arr[])
{
    return((ArraySize(arr) != 7) ? false : arr[DayOfWeek()]);
}


/**
 * 指定時刻での決済判定
 * exit_timeからinterval(秒)の間は決済と判定する
 *
 * @param exit_time  決済時刻
 * @param interval  決済時刻からの猶予時間
 *
 * @return  true: 決済
 */
bool ExitByTime(const datetime exit_time, const uint interval = 300)
{
    return(TimeCurrent() >= exit_time &&
        TimeCurrent() <= exit_time + interval);
}


/**
 * string型の時間をdatetime型に直す
 *
 * @param value  時刻の文字列, 例: 1:23
 *
 * @return 今日の日付（サーバー時刻）でdatetime型に変換したvalueの時刻
 */
datetime StringToTimeWithServerDate(const string value)
{
    return(StringToTime((string)Year() + "."
        + (string)Month() + "."
        + (string)Day() + " " + value));
}


/**
 * int型の時間をdatetime型に直す
 *
 * @param value  時刻
 *
 * @return 今日の日付（サーバー時刻）でdatetime型に変換したvalueの時刻
 */
datetime HourToTimeWithServerDate(const int value)
{
    return(StringToTime((string)Year() + "."
        + (string)Month() + "."
        + (string)Day()+ " "
        + IntegerToString(value) + ":00"));
}


/**
 * string型の時間を第2引数の日付でdatetime型に直す
 *
 * @param value  時刻
 * @param time  日付
 *
 * @return timeの日付でdatetime型に変換したvalueの時刻
 */
datetime StringToTimeWithRecievedDate(const string value, const datetime time)
{
    MqlDateTime now;
    TimeToStruct(time , now);

    return(StringToTime((string)now.year + "."
        + (string)now.mon + "."
        + (string)now.day + " " + value));
}


/**
 * string型の日本時間をサーバー時間のdatetime型に直す
 *
 * @param value  時刻の文字列, 例: 1:23
 * @param gmt_shift  サーバー時刻のGMTからの時差
 *
 * @return サーバー時刻に変換した時刻
 *
 * @dependencies StringToTimeWithServerDate
 */
datetime StringWithJpnTimeToTime(const string value, const int gmt_shift = 2)
{
    datetime jpn = StringToTimeWithServerDate(value);
    
    return(jpn - (9 - gmt_shift) * 3600);
}


/**
 * 現在のサーバー時刻から日本時間を求めて返す
 *
 * @param gmt_shift  サーバー時刻のGMTからの時差
 *
 * @return 日本時間
 */
datetime TimeJpn(const int gmt_shift = 2)
{
    return(TimeCurrent() + (9 - gmt_shift) * 3600);
}


/**
 * 現在のサーバー時刻から日本時間を求め、
 * 参照渡しされたMqlDateTime型のパラメーターに代入する
 *
 * @param gmt_shift サーバー時刻とGMTの時差（日本の時差は+9）
 * @param time 結果を受け取る構造体
 */
void TimeJpn(MqlDateTime &time)
{
    TimeToStruct(TimeJpn(), time);
}


/**
 * 取引時間帯を制限する
 *
 * @param start_time  取引時間の開始時刻
 * @param end_time  取引時間の終了時刻
 *
 * @return  true: 取引可能時刻, false: 取引不能時刻
 */
bool TradeTimeZoneFilter(const datetime start_time, const datetime end_time)
{
    if (start_time < end_time) {
        return(TimeCurrent() >= start_time && TimeCurrent() < end_time);
    }
   
    return(TimeCurrent() < end_time || TimeCurrent() >= start_time);
}


/**
 * 取引時間帯を制限する
 *
 * @param start_time  取引時間の開始時刻
 * @param end_time  取引時間の終了時刻
 *
 * @return  true: 取引可能時刻, false: 取引不能時刻
 *
 * @dependencies StringToTimeWithServerDate, TradeTimeZoneFilter
 */
bool TradeTimeZoneFilterByString(
    const string start_time,
    const string end_time)
{
    return(TradeTimeZoneFilter(
        StringToTimeWithServerDate(start_time),
        StringToTimeWithServerDate(end_time)));
}


/**
 * 欧州サマータイムであるかを判定する
 *
 * @return  true: 夏時間, false: 冬時間
 */
bool IsEuroSummerTime()
{
    int month = Month();
    int day = Day();
    
    if (month >= 11 || month <= 2) {
        return(false);
    } else if (month >= 4 && month <= 9) {
        return(true);
    } else if (month == 3) {
        if (day + 7 > 31) {
            return(true);
        } else {
            return(false);
        }
    } else { // Oct
        if (day + 7 > 31) {
            return(false);
        } else {
            return(true);
        }
    }
    return(true);
}


/**
 * 欧州サマータイムであるかを判定する
 *
 * @param value 判定する時刻
 *
 * @return  true: 夏時間, false: 冬時間
 */
bool IsEuroSummerTime(const datetime value)
{
    MqlDateTime date;
    TimeToStruct(value, date);
    int month = date.mon;
    int day = date.day;
    
    if (month >= 11 || month <= 2) {
        return(false);
    } else if (month >= 4 && month <= 9) {
        return(true);
    } else if (month == 3) {
        if (day + 7 > 31) {
            return(true);
        } else {
            return(false);
        }
    } else { // Oct
        if (day + 7 > 31) {
            return(false);
        } else {
            return(true);
        }
    }
    return(true);
}


/**
 * 米国サマータイムであるかを判定する
 *
 * @return  true: 夏時間, false: 冬時間
 */
bool IsUSASummerTime()
{
    int month = Month();
    int day = Day();
    
    if (month >= 12 || month <= 2) {
        return(false);
    } else if (month >= 4 && month <= 10) {
        return(true);
    } else if (month == 3) {
        if (day - 7 - DayOfWeek() > 0) {
            return(true);
        } else {
            return(false);
        }
    } else { // Nov
        if (day - DayOfWeek() > 0) {
            return(false);
        } else {
            return(true);
        }
    }
    return(true);
}


/**
 * 米国サマータイムであるかを判定する
 *
 * @param value 判定する時刻
 *
 * @return  true: 夏時間, false: 冬時間
 */
bool IsUSASummerTime(const datetime value)
{
    MqlDateTime date;
    TimeToStruct(value, date);
    int month = date.mon;
    int day = date.day;
    
    if (month >= 12 || month <= 2) {
        return(false);
    } else if (month >= 4 && month <= 10) {
        return(true);
    } else if (month == 3) {
        if (day - 7 - date.day_of_week > 0) {
            return(true);
        } else {
            return(false);
        }
    } else { // Nov
        if (day - date.day_of_week > 0) {
            return(false);
        } else {
            return(true);
        }
    }
    return(true);
}


/**
 * 週末の取引を制限する
 *
 * @param exit_day_of_week 決済曜日
 * @param exit_hour 決済時
 * @param exit_min 決済分
 *
 * @return  true: 取引可能, false: 取引不能
 */
bool WeekendFilter(
    const int exit_day_of_week = 5,
    const int exit_hour = 23,
    const int exit_min = 50)
{
    MqlDateTime now;
    TimeCurrent(now);
    
    if (now.day_of_week == exit_day_of_week) {
        if (now.hour > exit_hour) {
            return(false);
        } else if (now.hour == exit_hour && now.min == exit_min) {
            return(false);
        }
    } else if (now.day_of_week > exit_day_of_week) {
        return(false);
    }
    
    return(true);
}


/**
 * 週末の取引を制限する
 * パラメーターは日本時間で指定
 *
 * @param exit_day_of_week 決済曜日
 * @param exit_hour 決済時
 * @param exit_min 決済分
 *
 * @return  true: 取引可能, false: 取引不能
 */
bool WeekendFilterJpn(
    const int exit_day_of_week = 5,
    const int exit_hour = 23,
    const int exit_min = 50)
{
    MqlDateTime now;
    TimeJpn(now);
    
    if (now.day_of_week == exit_day_of_week) {
        if (now.hour > exit_hour) {
            return(false);
        } else if (now.hour == exit_hour && now.min >= exit_min) {
            return(false);
        }
    } else if (now.day_of_week > exit_day_of_week) {
        return(false);
    }
    
    return(true);
}


/**
 * 週初めの取引を制限する
 *
 * @param start_day_of_week 開始曜日
 * @param start_hour 開始時
 * @param start_min 開始分
 *
 * @return  true: 取引可能, false: 取引不能
 */
bool WeekStartFilter(
    const int start_day_of_week = 1,
    const int start_hour = 9,
    const int start_min = 00)
{
    MqlDateTime now;
    TimeCurrent(now);
    
    if (now.day_of_week == start_day_of_week) {
        if (now.hour < start_hour) {
            return(false);
        } else if (now.hour == start_hour && now.min < start_min) {
            return(false);
        }
    } else if (now.day_of_week < start_day_of_week) {
        return(false);
    }
    
    return(true);
}


/**
 * 1日のローソク足の本数
 *
 * @return 現在のチャートの時間足が、24時間に何本出現するか
 */
int GetBarsInDay()
{
    int period = _Period;
   
    if (period <= 0 || period > 1440) {
        return(0);
    }
   
    return(1440 / period);
}


/**
 * timeで指定された時刻が何本前のローソクかを算出する
 *
 * @param time 時間
 *
 * @return 指定された時間が何本前のローソク足か
 */
int TimeToShift(const datetime time)
{
    for (int i = 0; i < Bars; i++) {
        if (Time[i] <= time) {
            return(i);
        }
    }
    return(0);
}


/**
 * 時間足を文字列として返す
 *
 * @param period  時間足, 0は現在の時間足
 *
 * @return  時間足の日本語表示
 */
string PeriodToString(int period)
{
    if (period == 0) {
        period = _Period;
    }
   
    switch (period) {
        case PERIOD_M1:
            return("1分足 (M1)");
        case PERIOD_M5:
            return("5分足 (M5)");
        case PERIOD_M15:
            return("15分足 (M15)");
        case PERIOD_M30:
            return("30分足 (M30)");
        case PERIOD_H1: 
            return("1時間足 (H1)");
        case PERIOD_H4:
            return("4時間足 (H4)");
        case PERIOD_D1:
            return("日足 (D1)");
        case PERIOD_W1:
            return("週足 (W1)");
        case PERIOD_MN1:
            return("月足 (MN1)");
        default:
            return("");
    }
}


//--- Math Functions ---
/**
 * 配列の値の合計値を算出する
 *
 * @param &array  対象の配列
 *
 * @return 合計値
 */
double MathArraySum(double &array[])
{
    double sum = 0;
    int length = ArraySize(array);
    
    for (int i = 0; i < length; i++) {
        sum += array[i];
    }
    
    return(sum);
}


/**
 * 配列の値の平均値を算出する
 *
 * @param &array  対象の配列
 *
 * @return 平均値
 */
double MathArrayAverage(double &array[])
{
    double sum = 0;
    int length = ArraySize(array);
    
    if (length <= 0) {
        return(0);
    }
    
    for (int i = 0; i < length; i++) {
        sum += array[i];
    }
    
    return(sum / length);
}


/**
 * 配列の値の平均値を算出する
 * indexがshift番目における期間period平均
 *
 * @param &array  対象の配列
 * @param period  平均期間
 * @param shift  配列のindex
 *
 * @return 平均値
 */
double MathArrayAverage(double &array[], const int period, const int shift)
{
    double sum = 0;

    if (ArraySize(array) < shift + period || period <= 0 || shift < 0) {
        return(0);
    }
    
    for (int i = shift; i < period; i++) {
        sum += array[i];
    }
    
    return(sum / period);
}


/**
 * symbol, magicに一致するポジションの平均価格
 * ロット数で重み付けした平均値
 *
 * @param symbol  銘柄
 * @param magic  マジックナンバー
 *
 * @return 保有ポジションの平均価格
 */
double GetAveragePrice(const string symbol, const int magic)
{
    double price = 0;
    double lots = 0;
    
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
        
        lots += OrderLots();
        price += OrderOpenPrice() * OrderLots();
    }
    
    if (lots == 0) {
        return(0);
    }
    return(price / lots);
}
 

/**
 * minとmaxで指定された範囲内のランダムな数値を返す
 *
 * @param min  最小値
 * @param max  最大値
 *
 * @return  ランダムな数値
 */
int GetRandom(const int min, const int max)
{
    return(min + (int)(MathRand() * (max - min + 1.0) / (1.0 + 32767.0)));
}


/**
 * pips単位の値を価格単位へ変換する
 *
 * @param pips_value  pips単位の値
 * @param symbol  銘柄
 *
 * @return  価格単位の値
 */
double PipsToPrice(const double pips_value, const string symbol)
{
    double point = MarketInfo(symbol, MODE_POINT);
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    double mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
    
    return(pips_value * point * mult);
}


/**
 * point単位の値を価格単位へ変換する
 *
 * @param point_value  point単位の値
 * @param symbol  銘柄
 *
 * @return  価格単位の値
 */
double PointToPrice(const int point_value, const string symbol)
{
    double point = MarketInfo(symbol, MODE_POINT);
    
    return(point_value * point);
}


/**
 * point単位の値をpips単位へ変換する
 *
 * @param point_value  point単位の値
 * @param symbol  銘柄
 *
 * @return  pips単位の値
 */
double PointToPips(const int point_value, const string symbol)
{
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    double mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
    
    return((double)point_value / mult);
}


/**
 * pips単位の値をpoint単位へ変換する
 *
 * @param pips_value  pips単位の値
 * @param symbol  銘柄
 *
 * @return  point単位の値
 */
int PipsToPoint(const double pips_value, const string symbol)
{
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    int mult = (digits == 3 || digits == 5) ? 10 : 1;
    
    return((int)(pips_value * mult));
}


/**
 * 損益をpoint単位へ変換する
 *
 * @param profit  変換対象の損益
 * @param lots  取引数量
 * @param symbol  通貨ペア
 *
 * @return  pips単位の値
 */
double ProfitToPips(const double profit, const double lots, string symbol)
{
    double tick_value = MarketInfo(symbol, MODE_TICKVALUE);
    double point_value = profit / tick_value / lots;
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    double mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
    
    return(point_value / mult);
}


/**
 * 価格をpips単位へ変換する
 * エラーが発生した場合は0を返す
 *
 * @param price  変換対象となる価格
 * @param symbol  銘柄
 *
 * @return  pips単位の値
 */
double PriceToPips(const double price, const string symbol)
{
    double point = MarketInfo(symbol, MODE_POINT);
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    double mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
    
    if (point == 0 || mult == 0) {
        return(0);
    }

    return(price / point / mult);
}


//--- String Functions ---
/**
 * 通貨ペア名の後ろに付いている文字を取得する
 * テストの関係でパラメーターは必要
 *
 * @param symbol  通貨ペア名, 省略した場合はチャートの銘柄
 *
 * @return 通貨ペア名の後ろに付いている文字
 */
string GetSymbolEndingOfWord(string symbol = "")
{
    if (symbol == "") {
        symbol = _Symbol;
    }
    if (StringLen(symbol) < 6) {
        return("");
    }
    
    return(StringSubstr(symbol, 6, StringLen(symbol) - 6));
}


/**
 * 数値をカンマ区切りの文字列に変換する
 *
 * @param value  変換対象となる数値
 * @param digits  変換後の小数点以下桁数
 *
 * @return カンマ区切りの文字列に変換された数値
 */
string NumberToStringWithAddComma(double value, int digits)
{
    string result = DoubleToString(value, digits);
    int length = StringLen(DoubleToStr(MathFloor(value), 0));
    int size = (value >= 0) ? 1 : 2;
    int noof = (int)MathFloor((length - size) / 3);
    int first = (length - noof * 3 == 0) ? 3 : (length - noof * 3);

    if (noof == 0) {
        return(result);
    }
    
    for (int i = 0; i < noof; i++) {
        result = StringConcatenate(
            StringSubstr(result, 0, first + i * 4),
            ",",
            StringSubstr(result, first + i * 4));
    }

    return(result);
}


/**
 * valueをdelimiterで分割して配列に格納する
 *
 * @param string delimiter  区切り文字
 * @param string value  対象の文字列
 * @param string arr[]  結果を受け取る配列
 */
void StringExplode(const string delimiter, string value, string &arr[])
{
    StringReplace(value, " ", "");
    StringReplace(value, "　", "");
    
    int pos = 0;
    int size = 0;
    int length = StringLen(value);
    int delimiter_length = StringLen(delimiter);
    int i = 0;
    
    for (i = 0; i < length; i++) {
        if (StringSubstr(value, i, delimiter_length) == delimiter) {
            size++;
            ArrayResize(arr, size);
            arr[size - 1] = StringSubstr(value, pos, i - pos);
            pos = i + delimiter_length;
        }
    }
    
    if (pos != length + delimiter_length) {
        size++;
        ArrayResize(arr, size);
        arr[size - 1] = StringSubstr(value, pos, i - pos);
    }
}


/**
 * value内の小文字英字を大文字に変換数
 *
 * @param string value  変換対象の文字列
 *
 * @return  変換後の文字列
 */
string StringUpper(string value)
{
    string replace[26][2] = {
        {"A", "a"},
        {"B", "b"},
        {"C", "c"},
        {"D", "d"},
        {"E", "e"},
        {"F", "f"},
        {"G", "g"},
        {"H", "h"},
        {"I", "i"},
        {"J", "j"},
        {"K", "k"},
        {"L", "l"},
        {"M", "m"},
        {"N", "n"},
        {"O", "o"},
        {"P", "p"},
        {"Q", "q"},
        {"R", "r"},
        {"S", "s"},
        {"T", "t"},
        {"U", "u"},
        {"V", "v"},
        {"W", "w"},
        {"X", "x"},
        {"Y", "y"},
        {"Z", "z"}
    };
    
    for (int i = 0; i < 26; i++) {
        StringReplace(value, replace[i][1], replace[i][0]);
    }
    
    return(value);
}


/**
 * value内の大文字英字を小文字に変換数
 *
 * @param string value  変換対象の文字列
 *
 * @return  変換後の文字列
 */
string StringLower(string value)
{
    string replace[26][2] = {
        {"A", "a"},
        {"B", "b"},
        {"C", "c"},
        {"D", "d"},
        {"E", "e"},
        {"F", "f"},
        {"G", "g"},
        {"H", "h"},
        {"I", "i"},
        {"J", "j"},
        {"K", "k"},
        {"L", "l"},
        {"M", "m"},
        {"N", "n"},
        {"O", "o"},
        {"P", "p"},
        {"Q", "q"},
        {"R", "r"},
        {"S", "s"},
        {"T", "t"},
        {"U", "u"},
        {"V", "v"},
        {"W", "w"},
        {"X", "x"},
        {"Y", "y"},
        {"Z", "z"}
    };
    
    for (int i = 0; i < 26; i++) {
        StringReplace(value, replace[i][0], replace[i][1]);
    }
    
    return(value);
}


//--- Trade Functions ---
/**
 * 保有中ポジションの取引数量を取得する
 *
 * @param symbol  銘柄
 * @param type  検索タイプ
 * @param magic  マジックナンバー
 *
 * @return  該当ポジションの合計取引数量
 */
double GetOrderLots(const string symbol, int type, int magic)
{
    double lots = 0.0;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        switch (type) {
            case OP_BUY:
                if (OrderType() == OP_BUY) {
                    lots += OrderLots();
                }
                break;
            case OP_SELL:
                if (OrderType() == OP_SELL) {
                    lots += OrderLots();
                }
                break;
            case OP_BUYLIMIT:
                if (OrderType() == OP_BUYLIMIT) {
                    lots += OrderLots();
                }
                break;
            case OP_SELLLIMIT:
                if (OrderType() == OP_SELLLIMIT) {
                    lots += OrderLots();
                }
                break;
            case OP_BUYSTOP:
                if (OrderType() == OP_BUYSTOP) {
                    lots += OrderLots();
                }
                break;
            case OP_SELLSTOP:
                if (OrderType() == OP_SELLSTOP) {
                    lots += OrderLots();
                }
                break;
            case OPEN_POS:
                if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                    lots += OrderLots();
                }
                break;
            case ALL_POS:
                lots += OrderLots();
                break;
            case PEND_POS:
                if (OrderType() == OP_BUYLIMIT || 
                    OrderType() == OP_SELLLIMIT || 
                    OrderType() == OP_BUYSTOP || 
                    OrderType() == OP_SELLSTOP) {
                    lots += OrderLots();
                }
                break;
            default:
                break;
        }
    }
    return(lots);
}


/**
 * 保有中ポジションの件数を取得する
 *
 * @param symbol  銘柄
 * @param type  検索タイプ
 * @param magic  マジックナンバー
 *
 * @return  該当ポジションのポジション数
 */
int GetOrderCount(const string symbol, const int type, const int magic)
{
    int count = 0;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        switch (type) {
            case OP_BUY:
                if (OrderType() == OP_BUY) {
                    count++;
                }
                break;
            case OP_SELL:
                if (OrderType() == OP_SELL) {
                    count++;
                }
                break;
            case OP_BUYLIMIT:
                if (OrderType() == OP_BUYLIMIT) {
                    count++;
                }
                break;
            case OP_SELLLIMIT:
                if (OrderType() == OP_SELLLIMIT) {
                    count++;
                }
                break;
            case OP_BUYSTOP:
                if (OrderType() == OP_BUYSTOP) {
                    count++;
                }
                break;
            case OP_SELLSTOP:
                if (OrderType() == OP_SELLSTOP) {
                    count++;
                }
                break;
            case OPEN_POS:
                if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                    count++;
                }
                break;
            case ALL_POS:
                count++;
                break;
            case PEND_POS:
                if (OrderType() == OP_BUYLIMIT || 
                    OrderType() == OP_SELLLIMIT || 
                    OrderType() == OP_BUYSTOP || 
                    OrderType() == OP_SELLSTOP) {
                    count++;
                }
                break;
            default:
                break;
        }
    }
    return(count);
}


/**
 * 発注処理を実行する
 *
 * @param symbol  銘柄
 * @param type  取引種別
 * @param lots  取引数量
 * @param price  注文価格
 * @param slip  スリッページ(pips単位)
 * @param sl  損切り価格
 * @param tp  利食い価格
 * @param comment  コメント
 * @param magic  マジックナンバー
 *
 * @return  エラーコード, 0は正常終了
 *
 * @dependencies NormalizeLots, ErrorDescription, TradeTypeToString
 */
int Entry(
    const string symbol,
    const int type,
    double lots,
    double price,
    double slip,
    double sl,
    double tp,
    const string comment,
    const int magic)
{
    if (!IsTradeAllowed()) {
        return(7002);
    }

    int err = -1;
    int slippage = PipsToPoint(slip, symbol);
    color arrow = (type % 2 == 0) ? clrBlue : clrRed;
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   
    lots = NormalizeLots(lots, symbol);
    price = NormalizeDouble(price, digits);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);
 
    uint starttime = GetTickCount();
    while (true) {
        if (GetTickCount() - starttime > RETRY_TIME_LIMIT) {
            Print("OrderSend timeout.");
            return(7001);
        }
      
        ResetLastError();
        RefreshRates();
      
        int ticket = OrderSend(
            symbol,
            type,
            lots,
            price,
            slippage,
            sl,
            tp,
            comment,
            magic,
            0,
            arrow);
      
        if (ticket != -1) {
            return(0);
        }
      
        err = _LastError;
        Print("[OrderSendError] : ", err, " ", ErrorDescription(err));

        if (err == 129) {
            break;
        } else if (err == 130) {
            Print(
                "bid=", Bid, 
                " type=", TradeTypeToString(type), 
                " price=", price,
                " sl=", sl, " tp=", tp,
                " stoplevel=", MarketInfo(symbol, MODE_STOPLEVEL));
            break;
        } else if (err == 134) {
            break;
        } else if (err == 149) {
            break;
        } else if (err == 4110) {
            break;
        } else if (err == 4111) {
            break;
        }
      
        Sleep(RETRY_INTERVAL);
    }
    return(err);
}


/**
 * 取引数量を発注可能なロット数に合わせる
 *
 * @param lots  発注予定の取引数量
 * @param symbol  発注する通貨ペア名
 *
 * @return  正規化された取引数量
 */
double NormalizeLots(double lots, string symbol)
{
    double max = MarketInfo(symbol, MODE_MAXLOT);
    double min = MarketInfo(symbol, MODE_MINLOT);
   
    if (lots > max) {
        return(max);
    }
    if (lots < min) {
        return(min);
    }
    return(NormalizeDouble(lots, 2));
}


/**
 * 発注処理を実行する
 * TP/SLはpips単位で指定可能
 *
 * @param symbol  銘柄
 * @param type  取引種別
 * @param lots  取引数量
 * @param price  注文価格
 * @param slip  スリッページpips
 * @param sl  損切りpips
 * @param tp  利食いpips
 * @param comment  コメント
 * @param magic  マジックナンバー
 *
 * @return  エラーコード, 0は正常終了
 *
 * @dependencies PipsToPoint, PipsToPrice, Entry
 */
int EntryWithPips(
    const string symbol,
    const int    type,
    const double lots,
    const double price,
    const double slip,
    const double slpips,
    const double tppips,
    const string comment,
    const int    magic)
{
    double sl = 0;
    double tp = 0;

    if (type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) {
        if (slpips > 0) {
            sl = price + PipsToPrice(slpips, symbol);
        }
        if (tppips > 0) {
            tp = price - PipsToPrice(tppips, symbol);
        }
    } else {
        if (slpips > 0) {
            sl = price - PipsToPrice(slpips, symbol);
        }
        if (tppips > 0) {
            tp = price + PipsToPrice(tppips, symbol);
        }
    }
   
    return(Entry(symbol, type, lots, price, slip, sl, tp, comment, magic));
}


/**
 * 取引種別を文字列として返す
 *
 * @param type  取引種別
 *
 * @return  取引種別の文字列
 */
string TradeTypeToString(const int type)
{
    if (type > 5 || type < 0) {
        return("Invalid value");
    }
    
    string values[6] = {
        "OP_BUY",
        "OP_SELL",
        "OP_BUYLIMIT",
        "OP_SELLLIMIT",
        "OP_BUYSTOP",
        "OP_SELLSTOP"
    };
    
    return(values[type]);
}


/**
 * magicに一致するオープンポジションを決済する
 * 複数存在する場合は全て決済する
 *
 * @param symbol  銘柄
 * @param slippage  スリッページpips
 * @param magic  マジックナンバー
 *
 * @return  true: 決済成功, false: 失敗
 */
bool Exit(const string symbol, double slippage, const int magic)
{
    color arrow = clrNONE;
    int type;
    int slip = PipsToPoint(slippage, symbol);
   
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            return(false);
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        type = OrderType();
        if (type != OP_BUY && type != OP_SELL) {
            continue;
        }
        if (!IsTradeAllowed()) {
            continue;
        }
      
        arrow = (type % 2 == 0) ? clrBlue : clrRed;
        RefreshRates();
      
        bool result = OrderClose(
            OrderTicket(),
            OrderLots(),
            OrderClosePrice(),
            slip,
            arrow);
      
        if (result) {
            continue;
        }
      
        int err = GetLastError();
        Print("[OrderCloseError] : ", err, " ", ErrorDescription(err));
        if (err == 129) {
            break;
        }
        Sleep(RETRY_INTERVAL);
    }

    return(true);
}


/**
 * magicに一致するオープンポジションを半分決済する
 * 複数存在する場合は全て半分決済する
 *
 * @param symbol  銘柄
 * @param slippage  スリッページpips
 * @param magic  マジックナンバー
 * @param lots  初期ロット数
 *
 * @return  true: 決済成功, false: 失敗
 */
bool ExitHalf(
    const string symbol,
    const double slippage,
    const int magic,
    const double lots)
{
   double exit_lots = NormalizeDouble(lots / 2, 2);
   int slip = PipsToPoint(slippage, symbol);
   
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         break;
      }
      if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
         continue;
      }
      
      if (OrderLots() == lots) {
         if (OrderClose(OrderTicket(), exit_lots, OrderClosePrice(), slip)) {
            return(true);
         }
      } 
   }
   
   return(false);
}


/**
 * 固定幅のTP/SLにより成り行きで決済する
 * sl_pips, tp_pipsはどちらも0は無効
 *
 * @param symbol  銘柄
 * @param magic マジックナンバー
 * @param sl_pips 損切り値幅(pips)
 * @param tp_pips 利食い値幅(pips)
 *
 * @return true: 決済, false: 決済しない
 */
bool ExitTpSl(
    const string symbol,
    const int magic,
    const double sl_pips,
    const double tp_pips)
{
    if (GetOrder(symbol, magic) == false) {
        return(false);
    }
    
    int type = OrderType();
    double open_price = OrderOpenPrice();
   
    if (open_price <= 0 || type == -1) {
        return(false);
    }
   
    if (type == OP_BUY) {
        if (tp_pips > 0) {
            if (MarketInfo(symbol, MODE_BID) >= open_price + PipsToPrice(tp_pips, symbol)) {
                return(true);
            }
        }
        if (sl_pips > 0) {
            if (MarketInfo(symbol, MODE_BID) <= open_price - PipsToPrice(sl_pips, symbol)) {
                return(true);
            }
        }
    } else if (type == OP_SELL) {
        if (tp_pips > 0) {
            if (MarketInfo(symbol, MODE_ASK) <= open_price - PipsToPrice(tp_pips, symbol)) {
                return(true);
            }
        }
        if (sl_pips > 0) {
            if (MarketInfo(symbol, MODE_ASK) >= open_price + PipsToPrice(sl_pips, symbol)) {
                return(true);
            }
        }
    }
   
    return(false);
}


/**
 * 固定幅のTP/SLにより成り行きで決済する
 * sl_pips, tp_pipsはどちらも0は無効
 *
 * @param symbol  銘柄
 * @param magic マジックナンバー
 * @param buy_sl 買い損切り値幅(pips)
 * @param buy_tp 買い利食い値幅(pips)
 * @param sell_sl 売り損切り値幅(pips)
 * @param sell_tp 売り利食い値幅(pips)
 *
 * @return true: 決済, false: 決済しない
 */
bool ExitTpSlByType(
    const string symbol,
    const int magic, 
    const double buy_sl,
    const double buy_tp,
    const double sell_sl,
    const double sell_tp)
{
    if (GetOrder(symbol, magic) == false) {
        return(false);
    }
    
    int type = OrderType();
    double open_price = OrderOpenPrice();
   
    if (open_price <= 0 || type == -1) {
        return(false);
    }
   
    if (type == OP_BUY) {
        if (buy_tp > 0) {
            if (iHigh(symbol, 0, 1) >= open_price + PipsToPrice(buy_tp, symbol)) {
                return(true);
            }
        }
        if (buy_sl > 0) {
            if (iLow(symbol, 0, 1) <= open_price - PipsToPrice(buy_sl, symbol)) {
                return(true);
            }
        }
    } else if (type == OP_SELL) {
        if (sell_tp > 0) {
            if (iHigh(symbol, 0, 1) <= open_price - PipsToPrice(sell_tp, symbol)) {
                return(true);
            }
        }
        if (sell_sl > 0) {
            if (iLow(symbol, 0, 1) >= open_price + PipsToPrice(sell_sl, symbol)) {
                return(true);
            }
        }
    }
   
    return(false);
}


/**
 * オープンポジションを変更する
 *
 * @param symbol  銘柄
 * @param sl  損切り価格, 0を指定すると現在の価格のまま変更しない
 * @param tp  利食い価格, 0を指定すると現在の価格のまま変更しない
 * @param magic  注文変更ポジションのマジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies ErrorDescription
 */
bool Modify(const string symbol, double sl, double tp, const int magic)
{
    int ticket = 0;
    int digits;
    int type = -1;
    
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        type = OrderType();
        if (type == OP_BUY || type == OP_SELL) {
            ticket = OrderTicket();
            break;
        }
    }
    if (ticket == 0) {
        return(false);
    }
    
    digits = (int)MarketInfo(symbol, MODE_DIGITS);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);

    if (sl == 0) {
        sl = OrderStopLoss();
    }
    if (tp == 0) {
        tp = OrderTakeProfit();
    }
    if (OrderStopLoss() == sl && OrderTakeProfit() == tp) {
        return(false);
    }
   
    ulong start_time = GetTickCount();
    while (true) {
        if (GetTickCount() - start_time > RETRY_TIME_LIMIT) {
            Print("OrderModify timeout.");
            return(false);
        }
        if (IsTradeAllowed()) {
            ResetLastError();
            RefreshRates();
        
            if (OrderModify(ticket, 0, sl, tp, 0)) {
                return(true);
            }
         
            int err = GetLastError();
            Print("[OrderModifyError] : ", err, " ", ErrorDescription(err));
            if (err == 1) {
                break;
            }
            if (err == 130) {
                if (type == OP_BUY) {
                    Print("Bid : ", MarketInfo(symbol, MODE_BID),
                          " sl : ", sl,
                          " tp : ", tp,
                          " stop level : ", MarketInfo(symbol, MODE_STOPLEVEL));
                } else if (type == OP_SELL) {
                    Print("Ask : ", MarketInfo(symbol, MODE_ASK),
                          " sl : ", sl,
                          " tp : ", tp,
                          " stop level : ", MarketInfo(symbol, MODE_STOPLEVEL));
                }
                break;
            }
        }
        Sleep(RETRY_INTERVAL);
    }
    return(false);
}


/**
 * 指定されたチケット番号のオープンポジションを変更する
 *
 * @param sl  損切り価格, 0を指定すると現在の価格のまま変更しない
 * @param tp  利食い価格, 0を指定すると現在の価格のまま変更しない
 * @param ticket  注文変更ポジションのチケット番号
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies ErrorDescription
 */
bool ModifyWithTicket(double sl, double tp, const int ticket)
{
    int type = -1;
    int digits;
    string symbol;
    
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
            continue;
        }
        
        type = OrderType();
        break;
    }
    
    if (ticket == 0 || type == -1) {
        return(false);
    }
    
    symbol = OrderSymbol();
    digits = (int)MarketInfo(symbol, MODE_DIGITS);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);

    if (sl == 0) {
        sl = OrderStopLoss();
    }
    if (tp == 0) {
        tp = OrderTakeProfit();
    }
    if (OrderStopLoss() == sl && OrderTakeProfit() == tp) {
        return(false);
    }
   
    ulong start_time = GetTickCount();
    while (true) {
        if (GetTickCount() - start_time > RETRY_TIME_LIMIT) {
            Print("OrderModify timeout.");
            return(false);
        }
        if (IsTradeAllowed()) {
            ResetLastError();
            RefreshRates();
        
            if (OrderModify(ticket, 0, sl, tp, 0)) {
                return(true);
            }
         
            int err = GetLastError();
            Print("[OrderModifyError] : ", err, " ", ErrorDescription(err));
            if (err == 1) {
                break;
            }
            if (err == 130) {
                if (type == OP_BUY) {
                    Print("Bid : ", MarketInfo(symbol, MODE_BID),
                          " sl : ", sl,
                          " tp : ", tp,
                          " stop level : ", MarketInfo(symbol, MODE_STOPLEVEL));
                } else if (type == OP_SELL) {
                    Print("Ask : ", MarketInfo(symbol, MODE_ASK),
                          " sl : ", sl,
                          " tp : ", tp,
                          " stop level : ", MarketInfo(symbol, MODE_STOPLEVEL));
                }
                break;
            }
        }
        Sleep(RETRY_INTERVAL);
    }
    return(false);
}


/**
 * symbol, magicに一致するオープンポジション全てを変更する
 *
 * @param symbol  銘柄
 * @param sl  損切り価格, 0を指定すると現在の価格のまま変更しない
 * @param tp  利食い価格, 0を指定すると現在の価格のまま変更しない
 * @param magic  注文変更ポジションのマジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies ErrorDescription
 */
bool ModifyAll(const string symbol, double sl, double tp, const int magic)
{
    double new_sl;
    double new_tp;
    int ticket = 0;
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
        
        if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
            ticket = OrderTicket();
        } else {
            continue;
        }
        
        if (sl == 0) {
            new_sl = OrderStopLoss();
        } else {
            new_sl = NormalizeDouble(sl, digits);
        }
        
        if (tp == 0) {
            new_tp = OrderTakeProfit();
        } else {
            new_tp = NormalizeDouble(tp, digits);
        }
        
        if (OrderStopLoss() == new_sl && OrderTakeProfit() == new_tp) {
            continue;
        }
        
        if (OrderModify(ticket, 0, new_sl, new_tp, 0)) {
            Sleep(RETRY_INTERVAL);
            continue;
        }
     
        int err = GetLastError();
        Print("[OrderModifyError] : ", err, " ", ErrorDescription(err));
        if (err == 1) {
            continue;
        }
        if (err == 130) {
            if (OrderType() == OP_BUY) {
                Print("Bid : ", MarketInfo(symbol, MODE_BID),
                      " sl : ", sl,
                      " tp : ", tp,
                      " stop level : ", MarketInfo(symbol, MODE_STOPLEVEL));
            } else {
                Print("Ask : ", MarketInfo(symbol, MODE_ASK),
                      " sl : ", sl,
                      " tp : ", tp,
                      " stop level : ", MarketInfo(symbol, MODE_STOPLEVEL));
            }
            continue;
        }
        
        Sleep(RETRY_INTERVAL);
    }

    return(true);
}


/**
 * magicに一致する待機注文を削除する
 * 複数存在する場合は全て削除する
 *
 * @param symbol  銘柄
 * @param magic  マジックナンバー
 *
 * @return  true: 成功, false: 失敗
 */
bool Delete(const string symbol, const int magic)
{
    int type;
    color arrow;
   
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        type = OrderType();
        if (type == OP_BUYLIMIT || type == OP_SELLLIMIT
            || type == OP_BUYSTOP || type == OP_SELLSTOP) {
            arrow = (type % 2 == 0) ? clrBlue : clrRed;
            if (!OrderDelete(OrderTicket(), arrow)) {
                int err = GetLastError();
                Print("[OrderDeleteError] : ", err, " ", ErrorDescription(err));
                return(false);
            }
        }
    }
   
    return(true);
}


/**
 * ピラミッディング可能か判定する
 * 利益がpips以上ある場合はピラミッディング可能
 *
 * @param symbol  銘柄
 * @param pips  エントリー基準となる利益(pips単位)
 * @param magic  マジックナンバー
 *
 * @return  取引シグナル
 */
TRADE_SIGNAL Piramidding(
    const string symbol,
    const double pips,
    const int magic)
{
    if (GetOrder(symbol, magic) == false) {
        return(NO_SIGNAL);
    }
    
    int type = OrderType();
    double open_price = OrderOpenPrice();
    double entry_price = 0;
    
    if (type == OP_BUY) {
        entry_price = open_price + PipsToPrice(pips, symbol);
        if (MarketInfo(symbol, MODE_ASK) >= entry_price) {
            return(BUY_SIGNAL);
        }
    } else if (type == OP_SELL) {
        entry_price = open_price - PipsToPrice(pips, symbol);
        if (MarketInfo(symbol, MODE_BID) <= entry_price) {
            return(SELL_SIGNAL);
        }
    }
    
    return(NO_SIGNAL);
}


/**
 * lower～upperの値幅内で、baseから上下width pips間隔で指値注文を出す。
 *
 * @param symbol  銘柄
 * @param base  基準価格
 * @param lower  発注レンジ下限
 * @param upper  発注レンジ上限
 * @param width  発注間隔pips
 * @param lots  取引数量
 * @param sl  損切りpips
 * @param tp  利食いpips
 * @param magic  マジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies PipsToPrice, HasOrderByPrice, EntryWithPips
 */
bool RepeatOrder(
    const string symbol,
    const double base,
    const double lower,
    const double upper,
    const double width,
    const double lots,
    const double sl,
    const double tp,
    const int    magic)
{
    if (upper < lower || width <= 0) {
        return(false);
    }
   
    double price = base;
    int type;
    string comment = "";
    int code = 0;
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   
    while (price > lower) {
        price -= PipsToPrice(width, symbol);
    }
    price += PipsToPrice(width, symbol);
   
    while (price <= upper) {
        if (price < MarketInfo(symbol, MODE_ASK)) {
            type = OP_BUYLIMIT;
            comment = DoubleToString(price, digits);
        } else if (price > MarketInfo(symbol, MODE_BID)) {
            type = OP_SELLLIMIT;
            comment = DoubleToString(price * -1, digits);
        } else {
            price += PipsToPrice(width, symbol);
            continue;
        }
      
        if (!HasOrderByPrice(symbol, type, price, magic)) {
            code = EntryWithPips(symbol, type, lots, price, 0, sl, tp, comment, magic);
            if (code != 0) {
                return(false);
            }
        }
      
        price += PipsToPrice(width, symbol);
        Sleep(RETRY_INTERVAL);
    }
   
    return(true);
}


/**
 * lower～upperの値幅内で、baseから上下width pips間隔で待機注文を出す。
 * 待機注文は指値と逆指値の両方を発注する。
 *
 * @param symbol  銘柄
 * @param base  基準価格
 * @param lower  発注レンジ下限
 * @param upper  発注レンジ上限
 * @param width  発注間隔pips
 * @param lots  取引数量
 * @param sl  損切りpips
 * @param tp  利食いpips
 * @param magic  マジックナンバー
 *
 * @return  true: 成功, false: 失敗
 *
 * @dependencies PipsToPrice, HasOrderByPrice, EntryWithPips
 */
bool RepeatOrderHedge(
    const string symbol,
    const double base,
    const double lower,
    const double upper,
    const double width,
    const double lots,
    const double sl,
    const double tp,
    const int    magic)
{
    if (upper < lower || width <= 0) {
        return(false);
    }
   
    double price = base;
    int type_buy, type_sell;
    string comment_buy, comment_sell;
    int digits = (int)MarketInfo(symbol, MODE_DIGITS);
    
    while (price > lower) {
        price -= PipsToPrice(width, symbol);
    }
    price += PipsToPrice(width, symbol);
   
    while (price <= upper) {
        if (price < MarketInfo(symbol, MODE_ASK)) {
            type_buy = OP_BUYLIMIT;
            type_sell = OP_SELLSTOP;
        } else if (price > MarketInfo(symbol, MODE_BID)) {
            type_buy = OP_BUYSTOP;
            type_sell = OP_SELLLIMIT;
        } else {
            price += PipsToPrice(width, symbol);
            continue;
        }
      
        if (!HasOrderByPrice(symbol, type_buy, price, magic)) {
            comment_buy = DoubleToString(price, digits);
            if (EntryWithPips(symbol, type_buy, lots, price, 0, sl, tp, comment_buy, magic) != 0) {
                return(false);
            }
        }
        if (!HasOrderByPrice(symbol, type_sell, price, magic)) {
            comment_sell = DoubleToString(price, digits);
            if (EntryWithPips(symbol, type_sell, lots, price, 0, sl, tp, comment_sell, magic) != 0) {
                return(false);
            }
        }
      
        price += PipsToPrice(width, symbol);
        Sleep(RETRY_INTERVAL);
    }
   
    return(true);
}


/**
 * 取引種別type, エントリー価格price, マジックナンバーmagic
 * と一致するポジションが存在するか確認する
 *
 * @param symbol  銘柄
 * @param type  取引種別
 * @param price  価格
 * @param magic  マジックナンバー
 *
 * @return  true: ポジション有り, false: ポジション無し
 */
bool HasOrderByPrice(
    const string symbol,
    const int type,
    double price,
    const int magic)
{
    int order_type;
    string price_str;
    double comment_price;
    int digits;
    
    digits = (int)MarketInfo(symbol, MODE_DIGITS);
    price = NormalizeDouble(price, digits);
    if (type > 0) {
        price_str = DoubleToString(price, digits);
    }
    if (type < 0) {
        price_str = DoubleToString(price * -1, digits);
    }
   
   
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            return(true);
        }
        if (OrderSymbol() != symbol) {
            continue;
        }
        if (OrderMagicNumber() != magic) {
            continue;
        }
      
        order_type = OrderType();
        comment_price = StringToDouble(
            StringSubstr(OrderComment(), 0, StringLen(price_str)));
      
        if (type > 0) {
            if (order_type == OP_BUY ||
                order_type == OP_BUYLIMIT ||
                order_type == OP_BUYSTOP) {
                if (comment_price == price) {
                    return(true);
                }
            }
        }
        if (type < 0) {
            if (order_type == OP_SELL ||
                order_type == OP_SELLLIMIT ||
                order_type == OP_SELLSTOP) {
                if (comment_price == price * -1) {
                    return(true);
                }
            }
        }
    }
   
    return(false);
}


/**
 * 取引数量の複利計算
 * 計算が不可能な場合は0を返す
 *
 * @param risk  損切りの損失, 口座残高に対する割合(%)
 * @param sl_pips  損切り(pips)
 * @param symbol  銘柄
 *
 * @return  取引数量
 *
 * @dependencies PipsToPoint
 */
double MoneyManagement(
    const double risk,
    const double sl_pips,
    const string symbol)
{
    if (risk <= 0 || sl_pips <= 0) {
        return(0);
    }
   
    double lots = AccountBalance() * (risk / 100);
    double tickvalue = MarketInfo(symbol, MODE_TICKVALUE);

    if (tickvalue == 0) {
        return(0);
    }
   
    lots = lots / (tickvalue * PipsToPoint(sl_pips, symbol));
   
    return(lots);
}


/**
 * トレーリングストップを実行する
 * 対象はmagicで指定されたポジション1つ
 *
 * @param symbol  銘柄
 * @param value  トレーリング幅(pips)
 * @param magic  マジックナンバー
 *
 * @dependencies PipsToPrice, Modify
 */
void TrailingStop(const string symbol, const double value, const int magic)
{
    double new_sl;
   
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            return;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        if (OrderType() == OP_BUY) {
            new_sl = MarketInfo(symbol, MODE_BID) - PipsToPrice(value, symbol);
            if (new_sl >= OrderOpenPrice() && new_sl > OrderStopLoss()) {
                Modify(symbol, new_sl, 0, magic);
                break;
            }
        }
        if (OrderType() == OP_SELL) {
            new_sl = MarketInfo(symbol, MODE_ASK) + PipsToPrice(value, symbol);
            if (new_sl <= OrderOpenPrice() && 
                (new_sl < OrderStopLoss() || OrderStopLoss() == 0)) {
                Modify(symbol, new_sl, 0, magic);
                break;
            }
        }
    }
}


/**
 * トレーリングストップを実行する
 * 対象はmagicで指定されたポジション全て
 *
 * @param symbol  銘柄
 * @param value  トレーリング幅(pips)
 * @param magic  マジックナンバー
 *
 * @dependencies PipsToPrice, Modify
 */
void TrailingStopAll(const string symbol, const double value, const int magic)
{
    double new_sl;
   
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            return;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        if (OrderType() == OP_BUY) {
            new_sl = MarketInfo(symbol, MODE_BID) - PipsToPrice(value, symbol);
            if (new_sl >= OrderOpenPrice() && new_sl > OrderStopLoss()) {
                ModifyWithTicket(new_sl, 0, OrderTicket());
            }
        }
        if (OrderType() == OP_SELL) {
            new_sl = MarketInfo(symbol, MODE_ASK) + PipsToPrice(value, symbol);
            if (new_sl <= OrderOpenPrice() && 
                (new_sl < OrderStopLoss() || OrderStopLoss() == 0)) {
                ModifyWithTicket(new_sl, 0, OrderTicket());
            }
        }
    }
}


/**
 * 建値決済機能
 * value pipsだけ利益が出たポジションの決済SLをエントリー価格に設定する
 *
 * @param symbol  銘柄
 * @param value  利益(pips)
 * @param magic  マジックナンバー
 * @param pips  新しいSLの建値からの距離(pips)
 *
 * @dependencies PipsToPrice, Modify
 */
void BreakEven(
    const string symbol,
    const double value,
    const int magic,
    const double pips = 0)
{
    double new_sl;
    
    if (value <= pips) {
        return;
    }
   
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            return;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        if (OrderType() == OP_BUY) {
            new_sl = OrderOpenPrice() + PipsToPrice(pips, symbol);
            if (MarketInfo(symbol, MODE_BID) - PipsToPrice(value, symbol) >= OrderOpenPrice() &&
                new_sl > OrderStopLoss()) {
                Modify(symbol, new_sl, 0, magic);
                break;
            }
        }
        if (OrderType() == OP_SELL) {
            new_sl = OrderOpenPrice() - PipsToPrice(pips, symbol);
            if (MarketInfo(symbol, MODE_ASK) + PipsToPrice(value, symbol) <= OrderOpenPrice() &&
                (new_sl < OrderStopLoss() || OrderStopLoss() == 0)) {
                Modify(symbol, new_sl, 0, magic);
                break;
            }
        }
    }
}


/**
 * マーチンゲールによるロット数を計算する
 *
 * @param symbol  銘柄
 * @param base_lots 基本ロット数
 * @param lots_mult 連敗毎のロット倍率
 * @param magic マジックナンバー
 * @param max_lots 最大ロット数, 0は上限なし
 *
 * @return 取引数量
 */
double Martingale(
    const string symbol,
    const double base_lots,
    const double lots_mult,
    const int magic,
    const int max_lots = 0)
{
    int lose = 0;
    for (int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            continue;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
        if (OrderProfit() >= 0) {
            break;
        }
        lose++;
    }
    
    double lots = base_lots * MathPow(lots_mult, lose);
    
    if (max_lots > 0) {
        if (lots > max_lots) {
            return(max_lots);
        }
    }

    return(lots);
}


/**
 * トレードプールから最新のポジション情報を1件選択する
 *
 * @param symbol  銘柄
 * @param magic  マジックナンバー
 *
 * @return  true: 選択成功, false: 失敗
 */
bool GetOrder(const string symbol, const int magic)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
        return(true);
    }
    return(false);
}


/**
 * ヒストリープールから最新のポジション情報を1件選択する
 *
 * @param symbol  銘柄
 * @param magic  マジックナンバー
 *
 * @return  true: 選択成功, false: 失敗
 */
bool GetOrderByHistory(const string symbol, const int magic)
{
    for (int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
        return(true);
    }
    return(false);
}


/**
 * magicに一致する全ポジションの合計損益を取得して返す
 *
 * @param symbol  銘柄
 * @param magic  マジックナンバー
 *
 * @return  合計損益
 */
double GetOrderProfitTotal(const string symbol, const int magic)
{
    double profit = 0;
   
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderSymbol() != symbol || OrderMagicNumber() != magic) {
            continue;
        }
      
        profit += OrderProfit();
    }
   
    return(profit);
}


/**
 * スプレッドフィルター
 * 現在のスプレッドがspreadよりも大きければ取引しない
 * 
 * @param symbol  銘柄
 * @param spread  スプレッドの最大許容値(point単位)
 *
 * @return  true: 取引可能, false: 取引不可能
 */
bool SpreadFilter(const string symbol, const int spread)
{
    return(MarketInfo(symbol, MODE_SPREAD) <= spread);
}


/**
 * スプレッドフィルター
 * 現在のスプレッドがspreadよりも大きければ取引しない
 * 
 * @param symbol  銘柄
 * @param spread  スプレッドの最大許容値(pips単位)
 *
 * @return  true: 取引可能, false: 取引不可能
 */
bool SpreadFilter(const string symbol, const double spread)
{
    return(MarketInfo(symbol, MODE_SPREAD) <= PipsToPoint(spread, symbol));
}


/**
 * エラー内容を取得する
 *
 * @param error_code  エラーコード
 *
 * @return  エラー内容を表す文字列
 */
string ErrorDescription(int error_code)
{
    string error_string;

    switch (error_code) {
        case 0:
        case 1:
            error_string = "no error";
            break;
        case 2:
            error_string = "common error";
            break;
        case 3:
            error_string = "invalid trade parameters";
            break;
        case 4:
            error_string = "trade server is busy";
            break;
        case 5:
            error_string = "old version of the client terminal";
            break;
        case 6:
            error_string = "no connection with trade server";
            break;
        case 7:
            error_string = "not enough rights";
            break;
        case 8:
            error_string = "too frequent requests";
            break;
        case 9:
            error_string = "malfunctional trade operation (never returned error)";
            break;
        case 64:
            error_string = "account disabled";
            break;
        case 65:
            error_string = "invalid account";
            break;
        case 128:
            error_string = "trade timeout";
            break;
        case 129:
            error_string = "invalid price";
            break;
        case 130:
            error_string = "invalid stops";
            break;
        case 131:
            error_string = "invalid trade volume";
            break;
        case 132:
            error_string = "market is closed";
            break;
        case 133:
            error_string = "trade is disabled";
            break;
        case 134:
            error_string = "not enough money";
            break;
        case 135:
            error_string = "price changed";
            break;
        case 136:
            error_string = "off quotes";
            break;
        case 137:
            error_string = "broker is busy (never returned error)";
            break;
        case 138:
            error_string = "requote";
            break;
        case 139:
            error_string = "order is locked";
            break;
        case 140:
            error_string = "long positions only allowed";
            break;
        case 141:
            error_string = "too many requests";
            break;
        case 145:
            error_string = "modification denied because order too close to market";
            break;
        case 146:
            error_string = "trade context is busy";
            break;
        case 147:
            error_string = "expirations are denied by broker";
            break;
        case 148:
            error_string = "amount of open and pending orders has reached the limit";
            break;
        case 149:
            error_string = "hedging is prohibited";
            break;
        case 150:
            error_string = "prohibited by FIFO rules";
            break;
      
        // mql4 errors
        case 4000:
            error_string = "no error (never generated code)";
            break;
        case 4001:
            error_string = "wrong function pointer";
            break;
        case 4002:
            error_string = "array index is out of range";
            break;
        case 4003:
            error_string = "no memory for function call stack";
            break;
        case 4004:
            error_string = "recursive stack overflow";
            break;
        case 4005:
            error_string = "not enough stack for parameter";
            break;
        case 4006:
            error_string = "no memory for parameter string";
            break;
        case 4007:
            error_string = "no memory for temp string";
            break;
        case 4008:
            error_string = "not initialized string";
            break;
        case 4009:
            error_string = "not initialized string in array";
            break;
        case 4010:
            error_string = "no memory for array\' string";
            break;
        case 4011:
            error_string = "too long string";
            break;
        case 4012:
            error_string = "remainder from zero divide";
            break;
        case 4013:
            error_string = "zero divide";
            break;
        case 4014:
            error_string = "unknown command";
            break;
        case 4015:
            error_string = "wrong jump (never generated error)";
            break;
        case 4016:
            error_string = "not initialized array";
            break;
        case 4017:
            error_string = "dll calls are not allowed";
            break;
        case 4018:
            error_string = "cannot load library";
            break;
        case 4019:
            error_string = "cannot call function";
            break;
        case 4020:
            error_string = "expert function calls are not allowed";
            break;
        case 4021:
            error_string = "not enough memory for temp string returned from function";
            break;
        case 4022:
            error_string = "system is busy (never generated error)";
            break;
        case 4050:
            error_string = "invalid function parameters count";
            break;
        case 4051:
            error_string = "invalid function parameter value";
            break;
        case 4052:
            error_string = "string function internal error";
            break;
        case 4053:
            error_string = "some array error";
            break;
        case 4054:
            error_string = "incorrect series array using";
            break;
        case 4055:
            error_string = "custom indicator error";
            break;
        case 4056:
            error_string = "arrays are incompatible";
            break;
        case 4057:
            error_string = "global variables processing error";
            break;
        case 4058:
            error_string = "global variable not found";
            break;
        case 4059:
            error_string = "function is not allowed in testing mode";
            break;
        case 4060:
            error_string = "function is not confirmed";
            break;
        case 4061:
            error_string = "send mail error";
            break;
        case 4062:
            error_string = "string parameter expected";
            break;
        case 4063:
            error_string = "integer parameter expected";
            break;
        case 4064:
            error_string = "double parameter expected";
            break;
        case 4065:
            error_string = "array as parameter expected";
            break;
        case 4066:
            error_string = "requested history data in update state";
            break;
        case 4099:
            error_string = "end of file";
            break;
        case 4100:
            error_string = "some file error";
            break;
        case 4101:
            error_string = "wrong file name";
            break;
        case 4102:
            error_string = "too many opened files";
            break;
        case 4103:
            error_string = "cannot open file";
            break;
        case 4104:
            error_string = "incompatible access to a file";
            break;
        case 4105:
            error_string = "no order selected";
            break;
        case 4106:
            error_string = "unknown symbol";
            break;
        case 4107:
            error_string = "invalid price parameter for trade function";
            break;
        case 4108:
            error_string = "invalid ticket";
            break;
        case 4109:
            error_string = "trade is not allowed in the expert properties";
            break;
        case 4110:
            error_string = "longs are not allowed in the expert properties";
            break;
        case 4111:
            error_string = "shorts are not allowed in the expert properties";
            break;
        case 4200:
            error_string = "object is already exist";
            break;
        case 4201:
            error_string = "unknown object property";
            break;
        case 4202:
            error_string = "object is not exist";
            break;
        case 4203:
            error_string = "unknown object type";
            break;
        case 4204:
            error_string = "no object name";
            break;
        case 4205:
            error_string = "object coordinates error";
            break;
        case 4206:
            error_string = "no specified subwindow";
            break;
      
        // original errors
        case 7001:
            error_string = "trade timeout";
            break;
        case 7002:
            error_string = "trade is not allow";
            break;
        
        default:
            error_string = "unknown error";
            break;
    }

    return(error_string);
}


//--- Trade Functions ---
/**
 * Calculates the Rank Correlation Index indicator and returns its value.
 *
 * @param symbol     Symbol name on the data of which the indicator will be calculated.
 *                   NULL means the current symbol.
 * @param timeframe  Timeframe.
 *                   It can be any of ENUM_TIMEFRAMES enumeration values.
 *                   0 means the current chart timeframe.
 * @param period     Averaging period for calculation.
 * @param index      Index of the value taken from the indicator buffer
 *                   (shift relative to the current bar the given amount of periods ago).
 *
 * @return           Numerical value of the Rank Correlation Index indicator.
 */
double iRCI(const string symbol, int timeframe, int period, int index)
{   
    int rank;
    double d = 0;
    double close_arr[];
    ArrayResize(close_arr, period); 
    
    for (int i = 0; i < period; i++) {
        close_arr[i] = iClose(symbol, timeframe, index + i);
    }
    
    ArraySort(close_arr, WHOLE_ARRAY, 0, MODE_DESCEND);

    for (int j = 0; j < period; j++) {
        rank = ArrayBsearch(close_arr,
                            iClose(symbol, timeframe, index + j),
                            WHOLE_ARRAY,
                            0,
                            MODE_DESCEND);
        d += MathPow(j - rank, 2);
    }

    return((1 - 6 * d / (period * (period * period - 1))) * 100);
}
