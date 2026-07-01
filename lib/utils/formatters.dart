import 'package:intl/intl.dart';

class Formatters {
  static final _money = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  static final _date = DateFormat('dd/MM/yyyy');
  static final _time = DateFormat('h:mm a');

  static String money(double value) => _money.format(value);
  static String date(DateTime value) => _date.format(value);
  static String time(DateTime value) => _time.format(value);
}
