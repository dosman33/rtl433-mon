# Troubleshooting

## Problem: rtl433-html.sh is not removing unused columns
Answer: See the next problem. This only happens if colunn-reduce.sh is not giving you expected output.

## Problem: column-reduce.sh is not cutting out the empty columns
Answer: Double check your source rtl_433 .csv log file for multiple header rows. This will cause column-reduce.sh fail to remove the unused columns. It's a case of garbage-in garbage-out. While testing and setting these scripts up it's easy to have this happen and not realize it so double check.

