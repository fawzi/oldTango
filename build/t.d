module t;
import tango.core.stacktrace.TraceExceptions;

void f()
{
throw new Exception("pippo");
}

void main(){
 f();
}