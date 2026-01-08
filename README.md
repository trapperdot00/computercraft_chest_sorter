# ComputerCraft Inventory Manager

## Installation
1. Create a directory for the program and navigate into it.
```
mkdir chest
cd chest
```

2. Download `install.lua`.
```
wget https://raw.githubusercontent.com/trapperdot00/cc-tweaked_inventory_manager/refs/heads/master/install.lua
```

> Alternatively, you can drag and drop it from your computer.

3. Run `install.lua`.
```
install
```

This creates the directory structure for the program and populates them with the downloaded files.

## Usage
Command-line arguments are used to execute the desired actions.

Arguments ending with an `=` accept one or more arguments.
When supplying more than one argument, separate them with commas __without whitespace__.

The program distinguishes two kinds of inventory peripherals:
- inputs
- outputs

### Before first use
1. Connect the inventory peripherals to the computer.
2. Select the input inventories using `--configure`.
3. Scan the chest contents using `--scan`.

### Scanning
`--scan` iterates over each connected inventory peripheral's slots to update:
- the inventory database
- the item stack-size database.

Manual scanning is required when items are manually removed or inserted from the output inventory peripherals.

Input inventory peripherals are rescanned after movement operations.

### Item moving
Items can be transferred between input and output inventory peripherals.

#### Pushing
`--push` moves items from the input inventory's slots into the output inventories.

#### Pulling
`--pull` moves items from the output inventory's slots into the input inventories.

#### Retrieving selected item(s)
`--get=` pulls only the selected items into the input inventories.

To retrieve a single item out of the system:
```
main --get=minecraft:dirt
```
To retrieve multiple items:
```
main --get=minecraft:stick,minecraft:coal,minecraft:torch
```

### Queries
Use queries to determine the state of the managed inventory system.

#### Total managed size
`--size ` returns the total amount of slots for
- input inventories
- output inventories
- the entire system

#### Slot statistics
`--usage` returns the count of
- used output slots
- all output slots
- the usage ratio

#### Item count
`--count=` returns the total amount of the specified item(s).

#### Item physical location
`--find=` returns each inventory peripheral's ID that contains the specified item(s).
