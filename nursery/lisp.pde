#include <AikoSExpression.h>

using namespace Aiko;

void setup() {
  Serial.begin(9600);
}

void println(char* buffer, int length) {
  for (int i = 0; i < length; i++)
    Serial.write(buffer[i]);
  Serial.println();  
}

void loop() {
  static char buffer[64];
  static int i = 0;
 
  while (!Serial.available());
  char c = Serial.read();
  if (c == ';') {
    println(buffer, i);
    Serial.print("=> ");
    Serial.println(eval(buffer, i));
    i = 0;
  }
  else
    buffer[i++] = c;
}

int eval(SExpression& expression);
int eval(SExpressionArray& array);
int parseInt(SExpression& expression);

int eval(char* buffer, int length) {
  SExpression expression;
  expression.scan(buffer, length);
  eval(expression);
}

int eval(SExpression& expression) {
  if (expression.isArray()) {
    SExpressionArray array;
    array.parse(expression);
    return eval(array);
  }
  else {
    return parseInt(expression);
  }
}

int eval(SExpressionArray& array) {
  int n;
  switch (*array[0].head()) {
    case '+':
      n = 0;
      for (int i = 1; i < array.length(); i++) n+= eval(array[i]);
      break;
    case '-':
      n = parseInt(array[1]);
      for (int i = 2; i < array.length(); i++) n -= eval(array[i]);
      break;
    case '*':
      n = 1;
      for (int i = 1; i < array.length(); i++) n*= eval(array[i]);
      break;
    case '/':
      n = parseInt(array[1]);
      for (int i = 2; i < array.length(); i++) n /= eval(array[i]);
      break;
  }
  return n;
}

int parseInt(SExpression& expression) {
  int sign = 1;
  int n = 0;
  for (int i = 0; i < expression.size(); i++) {
    if (i == 0 && expression.head()[0] == '-') {
      sign = -1;
    }
    else {
      n *= 10;
      n += (expression.head()[i] - '0');
    }
  }
  return sign * n;
}
