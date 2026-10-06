public with sharing class MultiplyUtil {
   
    public static Decimal multiply(Decimal a, Decimal b) {
        return a * b;
    }
    public static Decimal multiplyManual(Decimal a, Decimal b) {
        Decimal result = 0;
        for(Integer i=0;i<b;i++){
            result += a;
        }
        return result;
    }

    /**
     * 3,4
     * 3 + 3 + 3 + 3 = 12
     */
}