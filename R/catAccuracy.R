#' Accuracy by categories
#'
#' Checks accuracy of classification by category. Provides details by category including: true positive rate, positive predicted value, true frequency in training data, and the top five classes observations from a given category are mistakenly classified into.
#' @param true The numeric vector of true codings
#' @param predicted One numeric vector of predicted codings from \code{classifyNB}
#' @param latexfile Logical indicating whether the user wants a latex table of results output into the current working directory.
#' @param filename String name for the output file. Defaults to \code{category_accuracy.tex}
#'
#' @return A dataframe with one row for each class. Columns correspond to within-class measures of: true positive rate, positive predicted value, true frequency in training data, and the top five classes observations from the given category are mistakenly classified into.
#'
#' @author Matt W. Loftis
#' @examples
#'   ## Load data and create document-feature matrices
#'   train_corpus <- quanteda::corpus(x = training_agendas$text)
#'   metadoc(train_corpus, "language") <- "danish"
#'   train_matrix <- quanteda::dfm(train_corpus,
#'                                 stem = TRUE,
#'                                 removeNumbers = FALSE)
#'
#'   est <- trainNB(training_agendas$coding, train_matrix)
#'   out <- classifyNB(est, train_matrix, training_agendas)
#'   acc <- catAccuracy(true = out$coding, predicted = out$ratio_match)
#'
#' @note Latex table outputs depend on the Latex packages: longtable and xcolor. Include the lines:
#' \code{\\usepackage\[table\]\{xcolor\}}
#' \code{\\usepackage\{longtable\}}
#' in Latex header
#'
#' @rdname catAccuracy
#' @import Matrix quanteda
#' @export

catAccuracy <- function(true, predicted, latexfile = FALSE, filename = "category_accuracy.tex"){
  ##Error catching and warnings
  if (!is.numeric(true)) {
    stop('Coding is not numeric. agendacodeR currently requires numeric codings.')
  }
  if (!is.numeric(predicted)) {
    stop('Coding is not numeric. agendacodeR currently requires numeric codings.')
  }

  ##Analyze accuracy
  tab <- as.matrix(table(true, predicted))
  by.row <- tab/Matrix::rowSums(tab)
  by.col <- t(t(tab)/Matrix::colSums(tab))
  frequencies <- Matrix::rowSums(tab)
  results <- data.frame(true = as.character(rownames(tab)),
                        true.pos.rate = rep(NA, nrow(tab)),
                        pos.pred.val = rep(NA, nrow(tab)),
                        frequency = rep(NA, nrow(tab)),
                        first = rep(NA, nrow(tab)),
                        second = rep(NA, nrow(tab)),
                        third = rep(NA, nrow(tab)),
                        fourth = rep(NA, nrow(tab)),
                        fifth = rep(NA, nrow(tab)))
  for (j in 1:nrow(tab)) {
    line <- by.row[rownames(tab)[j], ]
    if (rownames(tab)[j] %in% names(line)) {
      results[j, 2] <- signif(line[names(line) == rownames(tab)[j]], digits = 3)
      top <- line[names(line) != rownames(tab)[j]]
      top <- top[order(top, decreasing = TRUE)]
      top <- top[top > 0]
      top <- top[1:5]
      names(top)[is.na(names(top))] <- "n/a"
      results[j, 5:ncol(results)] <- names(top)
    } else {
      results[j, 2] <- 0
      results[j, 3:ncol(results)] <- rep("n/a", (ncol(results) - 2))
    }
    if (rownames(tab)[j] %in% colnames(tab)) {
      column <- by.col[, rownames(tab)[j]]
      results[j, 3] <- signif(column[names(column) == rownames(tab)[j]], digits = 3)
    } else {
      results[j, 3] <- "n/a"
    }
    results[j, 4] <- frequencies[rownames(tab)[j]]
  }
  results <- results[order(results[,2], decreasing = TRUE),]
  rownames(results) <- NULL
  results$true <- as.character(results$true)
  if (latexfile == FALSE) {
    return(results)
  } else {
    output <- paste("% latex table generated in R by agendacodeR -- github.com/mattwloftis/agendacodeR
%", Sys.Date(), "
\\begin{center}
\\begin{footnotesize}
\\begin{longtable}{", paste(rep("c", ncol(results)), collapse = "|"),"}
\\hline
\\rowcolor{lightgray}
Class & True Positive & Positive & True &", paste0("\\multicolumn{", 5, "}{c}{Top Mistaken Classes}"),"\\\\
\\rowcolor{lightgray}
 & Rate & Predictive Value & Frequency &", paste0("(", 1:5, ")", collapse = "&"), "\\\\
\\hline
\\endhead
")
    for (j in 1:nrow(results)) {
      output <- paste(output,
                      paste(results[j, ], collapse = "&"), "\\\\
")
    }
    output <- paste(output, "\\hline
\\caption{Accuracy by category \\label{tab:accuracy}}
\\end{longtable}
\\end{footnotesize}
\\end{center}
")
    zz <- file(filename, "w")
    cat(output, file = zz)
    close(zz)
    return(results)
  }
}
