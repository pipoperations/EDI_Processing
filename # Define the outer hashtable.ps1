# Define the outer hashtable
$outerHashtable = @{}

# Loop to create inner hashtables and add them to the outer hashtable
for ($i = 0; $i -lt 5; $i++) {
    # Define the inner hashtable
    $innerHashtable = @{}

    # Loop to populate the inner hashtable with random key-value pairs
    for ($j = 0; $j -lt 5; $j++) {
        # Generate a random key and value
        $key = Get-Random -Minimum 1 -Maximum 100
        $value = Get-Random -Minimum 1 -Maximum 100

        # Add the key-value pair to the inner hashtable
        $innerHashtable.Add($key, $value)
    }

    # Add the inner hashtable to the outer hashtable
    $outerHashtable.Add("InnerHashtable$i", $innerHashtable)
}

# Display the contents of the hashtable of hashtables
$outerHashtable
