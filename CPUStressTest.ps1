# Configure CPU Stress Test - number of cores
$coreTotal = 4

foreach ($Number in 1..$coreTotal){
	start-job -ScriptBlock{
	$result = 1; foreach ($number in 1..2147483647) {$result = $result * $number}
	}
}