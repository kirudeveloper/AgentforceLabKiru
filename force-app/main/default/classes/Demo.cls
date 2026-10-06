/**
 * 
 * Class - Demo
 */

private static void demoClass() {
    System.debug('Hello World');

       System.debug('This is a demo class.');
    Integer i= 10;
    Integer a = 5;
    Integer b = 7;
    Integer sum = a + b;
    System.debug('The sum of ' + a + ' and ' + b + ' is ' + sum);
    // Demo methods for all major Apex collection types

    // List demo
    List<String> names = new List<String>{'Alice', 'Bob', 'Charlie'};
    printNames(names);

    // Set demo
    Set<Integer> numbers = new Set<Integer>{1, 2, 3};
    printNumbers(numbers);

    // Map demo
    Map<String, Integer> fruitsToCount = new Map<String, Integer>{
        'Apples' => 5,
        'Oranges' => 3,
        'Bananas' => 7
    };
    printFruitCounts(fruitsToCount);

    // List method
    private static void printNames(List<String> nameList) {
        for (String name : nameList) {
            System.debug('Name: ' + name);
        }
    }

    // Set method
    private static void printNumbers(Set<Integer> numberSet) {
        for (Integer num : numberSet) {
            System.debug('Number: ' + num);
        }
    }

    // Map method
    private static void printFruitCounts(Map<String, Integer> fruitMap) {
        for (String fruit : fruitMap.keySet()) {
            System.debug('There are ' + fruitMap.get(fruit) + ' ' + fruit);
        }
    }



       
 }