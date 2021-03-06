/*
 * Schreiben sie ein Programm,dass ihnen für eine bestimmte Stelle,
 * die zugehörige Fibonacci Zahl ausgibt.
 */
package fibonacci;

/*
 * @author Tobias Günther
 */
public class Fibonacci {

    public static void main(String[] args) {
        int fragestelle = 9;            //Gefragte Stelle
        int result = fibo(fragestelle); //Übergeben der Variable 
        System.out.println(result);     //Ergebnisausgabe
        
    }

    public static int fibo(int fragestelle) {
        int result; //Definiton der Variable für das Ergebnis
        
       
        if (fragestelle == 2) {         //Sonderfall: 2=1
            return 1;
        } else if (fragestelle == 1) {  //Sonderfall: 1=1
            return 1;
        } else {
            result = fibo(fragestelle - 1) + fibo(fragestelle - 2);  
            // fib(n)=(fib(n-1)+(fibn-2) [2vorherigen StellenAddieren]         
                
        }
        return result;
    }
}

