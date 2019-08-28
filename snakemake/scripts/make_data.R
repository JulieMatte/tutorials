#!/usr/bin/env Rscript

gzfh <- gzfile("demo_data.tsv.gz", "w", compression = 9)

write.table(
    iris,
    gzfh,
    row.names = FALSE,
    col.names = TRUE, quote = FALSE,
    sep = "\t",
    na = ""
)

close(gzfh)
