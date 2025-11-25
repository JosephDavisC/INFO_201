#!/usr/bin/env Rscript
library(tidyverse, quietly = TRUE)
library(ollamar)

## For images, 'qwen3-vl:2b' worked very well for me,
##   uses 2-5G ram, depending on the image
##   timings (qwen3-vl:2b):
##      * cai lun: 10m, wedding photo 159s
##      * nick: 860min, wedding photo 8347s
##      * johan: 300m, wedding photo 3980s
##      * is-otoometlc9: (on power) 79m, wedding photo 900s
##      *                (on battery) 79m, wedding photo 900s (did not work?), eats 40% battery
##      * is-otoometd5060: 205m, wedding photo 1880s
##      
## Can also use 'llava', takes 5.7G ram
model <- "qwen3-vl:8b"
cat("Using", model, "model\n")
picFolder <- "picFolder"
options(timeout = 1e4)  # for slow computers

## Can it recognize and translate handwritten Chinese?
cat("\nRecognize/translate the poem\n")
tictoc::tic()
generate(model,
         prompt = "
This is a handwritten Chinese poem.
Read and print it, and translate it to English.
",
images = file.path(picFolder, "poem.jpg"),
output = "text") %>%
      strwrap() %>%
      paste(collapse = "\n") %>%
      cat("\n\n")
tictoc::toc()

pics <- list.files(picFolder) |>
   setdiff("poem.jpg")  # to have better comparability

cat("Pictures:\n")
for(pic in pics) {
   cat(pic)  # print here for debugging
   picPath <- paste(picFolder, pic, sep = "/")
   info <- magick::image_read(picPath) |>
      magick::image_info()
   cat(": ", info$width, "x", info$height, "\n")
   tictoc::tic()
   resp <- generate(model,
                    prompt = "What is on the picture?",
                    images = picPath,
                    output = "text",
                    keep_alive = "60m")
   tictoc::toc()
   resp %>%
      strwrap() %>%
      paste(collapse = "\n") %>%
      cat("\n\n")
}


cat("\nFind the student number\n")
for(pic in pics) {
   cat(pic)
   picPath <- paste(picFolder, "husky-card-husky.jpg", sep = "/")
   info <- magick::image_read(picPath) |>
      magick::image_info()
   cat(": ", info$width, "x", info$height, "\n")
   tictoc::tic()
   resp <- generate(model,
                    prompt = "
What is on the picture?

Is this an image of a student ID card?

If yes, find the student number and reply
**student number **<number>**
",
                    images = picPath,
output = "text")
   tictoc::toc()
   resp %>%
      strwrap() %>%
      paste(collapse = "\n") %>%
      cat("\n\n")
}


## Can it tell when was the pic taken?
## correct answer: 1940-07-25
cat("\nWhen was the picture taken?\n")
tictoc::tic()
generate(model,
         prompt = "This is an old wedding photo.
What do you think, when was this picture taken?",
images = file.path(picFolder, "wedding.jpg"),
output = "text") %>%
      strwrap() %>%
      paste(collapse = "\n") %>%
      cat("\n\n")
tictoc::toc()
