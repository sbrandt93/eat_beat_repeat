/// Ein einfacher Wrapper, um 'null' als expliziten Wert zu übergeben.
class Wrapper<T> {
  final T? value;
  const Wrapper(this.value);
}
