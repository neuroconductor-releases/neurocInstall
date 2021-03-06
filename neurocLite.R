# neurocInstall package version: 0.12.0
pkg_ver = '# neurocInstall package version: 0.12.0'
# source("https://bioconductor.org/biocLite.R")
# biocLite(suppressUpdates = TRUE,
#          suppressAutoUpdate = TRUE,
#          ask = FALSE)
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(update = FALSE, ask = FALSE)
# if (!require("neurocInstall")) {
#########################################
# Checking devtools version
#########################################
get_devtools_version = function() {
  ipacks = installed.packages()
  dtools = ipacks[ ipacks[, "Package"] %in% "devtools", "Version"]
  return(dtools)
}
# needed for bioc stuff
req_version = "1.12.0.9000"
dtools = get_devtools_version()
install_from_cran = FALSE
if (length(dtools) == 0 ) {
  install_from_cran = TRUE
} else {
  # too low of a version
  install_from_cran = compareVersion(dtools, req_version) < 0
}
if (install_from_cran) {
  install.packages("devtools")
}

# now we assume devtools is installed
dtools = get_devtools_version()
if (length(dtools) == 0 ) {
  stop(paste0("devtools tried to install but could not ",
              "- try to install devtools manually.",
              "Version >= ", req_version, " required."
  )
  )
} else {
  comparison = compareVersion(dtools, "1.12.0.9000")
  if (comparison < 0) {
    devtools::install_github("r-lib/devtools")
  }
}
message(paste("Using neurocLite version:", pkg_ver))

	#' @title Neuroconductor Installer
	#' @description Install function for neuroconductor packages
	#' @param repo Package name in neuroconductor
	#' @param release Stable or current (development) versions/branches
	#' @param release_repo Repository for release repository, passed to
	#' \code{\link{install.packages}}.  If \code{release_repo = "github"},
	#' then it will install using GitHub.  If you set this using
	#' \code{\link{make_release_version}} or specify the URL directly,
	#' it will override \code{release} option.
	#'
	#' @param type character, indicating the type of package to download and
	#' install, passed to \code{\link{install.packages}}.
	#'
	#' @param upgrade_dependencies Should dependencies be updated?
	#' passed to \code{\link[devtools]{install}} if using
	#' \code{release_repo = "github"}
	#' @param ... additional arguments passed to
	#' \code{\link{install.packages}}
	#' or \code{\link[devtools]{install_github}} if
	#' \code{release_repo = "github"}
	#'
	#' @return Result from  \code{\link{install.packages}} or
	#' \code{\link[devtools]{install_github}}
	#'
	#' @export
	#' @importFrom devtools install_github
	#' @importFrom utils read.csv
	#' @importFrom utils compareVersion install.packages installed.packages
	#'
	#' @examples
	#' \donttest{
	#'    tlib = tempfile()
	#'    dir.create(tlib, showWarnings = FALSE)
	#'    system.time({
	#'    install.packages("oro.asl",
	#'    lib = tlib,
	#'    repos = "https://neuroconductor.org/releases/2019/12/")
	#'    })
	#'    repos = getOption("repos")
	#'    print(repos)
	#'    #if (repos["CRAN"] == "@CRAN@") {
	#'    #    repos["CRAN"] = "https://cloud.r-project.org"
	#'    #    options(repos = repos)
	#'    #}
	#'    options(repos = NULL)
	#'    print(getOption("repos"))
	#'    neuro_install("oro.asl", lib = tlib,
	#'    release_repo = "https://neuroconductor.org/releases/2019/12")
	#'    options(repos = repos)
	#'  }
	#' \dontrun{
	#'    neuro_install("cifti", type = "source", lib = tlib)
	#'    neuro_install("cifti",
	#'    release_repo = latest_neuroc_release("stable"),
	#'    lib = tlib)
	#'
	#'    neuro_install("cifti", release_repo = "github")
	#' }
	#'
	neuro_install = function(
	  repo,
	  release = c("stable", "current"),
	  release_repo = latest_neuroc_release(),
	  upgrade_dependencies = FALSE,
	  type = getOption("pkgType"),
	  ...){
	
	  #############################
	  # Create a data.frame for merging
	  #############################
	  release = match.arg(release)
	
	  l_repo = trimws(tolower(release_repo))
	
	  if (!l_repo %in% "github") {
	    args = list(...)
	    repos = args$repos
	    repos = c(Neuroconductor = release_repo,
	              getOption("repos"),
	              repos)
	    args$repos = repos
	    contriburl = utils::contrib.url(repos, type)
	    repos = c(Neuroconductor = release_repo,
	              getOption("repos"),
	              repos)
	    repos = repos[ repos != "@CRAN@" ]
	    if ("contriburl" %in% names(args)) {
	      args$contriburl = c(contriburl, args$contriburl)
	    }
	    repos = repos[!duplicated(repos)]
	    args$contriburl = unique(args$contriburl)
	    args$pkgs = repo
	    # args$repos = repos
	    args$type = type
	    x = do.call(utils::install.packages, args = args)
	    # x = install.packages(pkgs = repo,
	    #                      repos = c(Neuroconductor = release_repo,
	    #                                getOption("repos")),
	    #                      type = type,
	    #
	    #                      ...)
	    lib.loc = NULL
	    if (!is.null(args$lib)) {
	      lib.loc = args$lib
	    }
	    not_installed = repo[!repo %in% installed.packages(
	      lib.loc = lib.loc
	    )[, "Package"]]
	    if (length(not_installed) > 0) {
	      msg = paste0("Package(s): ", paste(not_installed, sep = ", "),
	                   " released binaries/sources were not installed,",
	                   " please try to install with release_repo = \"github\"")
	      warning(msg)
	    }
	    return(invisible(x))
	  }
	
	  df = data.frame(repo = repo, stringsAsFactors = FALSE)
	
	  tab = neuro_package_table(long = TRUE)
	  tab = tab[ tab$release %in% release, ]
	
	  ## import list of packages
	  # error if pkg not in list of packages
	  check_install = df$repo %in% tab$repo
	  if (!all(check_install)) {
	    bad_pkgs = df$repo[!check_install]
	    bad_pkgs = paste(bad_pkgs, collapse = ", ")
	    message(paste0("Available Packages on neuroconductor are ",
	                   paste(unique(tab$repo), collapse = ", ")))
	    stop(paste0("Package(s) ", bad_pkgs,
	                " are not in neuroconductor"))
	  }
	  tab = merge(df, tab, by = "repo", all.x = TRUE)
	  tab$version = numeric_version(tab$version)
	
	  # pkg = tab$pkg
	  # tab$commit_id = tab[, "commit_id"]
	  tab = split(tab, tab$repo)
	  tab = lapply(tab, function(x) {
	    x$version = x[, "version"]
	    max_version = max(x$version)
	    x = x[ x$version %in% max_version,, drop = FALSE]
	    return(x)
	  })
	  tab = do.call("rbind", tab)
	  tab = data.frame(tab, stringsAsFactors = FALSE)
	  tab$repo = paste0("neuroconductor/", tab$repo, "@", tab$commit_id)
	
	  args = list(tab$repo)
	  gh_func = devtools::install_github
	  if ("upgrade" %in% methods::formalArgs(gh_func)) {
	    args$upgrade = upgrade_dependencies
	  } else {
	    args$upgrade_dependencies = upgrade_dependencies
	  }
	
	  if (!upgrade_dependencies) {
	    res = try({
	      results = do.call(gh_func, args = args)
	    })
	    if (is.logical(results)) {
	      check = any(!results)
	    } else {
	      check = FALSE
	    }
	    if (inherits(res, "try-error") || check) {
	      stop("Installation failed, please try with upgrade_dependencies = TRUE")
	    }
	  } else {
	    results = do.call(gh_func, args = args)
	  }
	}
	
	#' @rdname neuro_install
	#' @aliases neuroc_install
	#' @aliases neuro_install
	#' @export
	neuroc_install = function(...) {
	  neuro_install(...)
	}
	
	#' @rdname neuro_install
	#' @aliases neurocLite
	#' @export
	neurocLite = function(...) {
	  neuro_install(...)
	}
	
	#' @title Make Full Package Version
	#' @description Makes a package version to have all the same length.
	#' This is helpful when using \code{\link{compareVersion}}.
	#'
	#' @param x Character vector of package versions
	#'
	#' @return Character vector of versions, each with the same length.
	#' @export
	#'
	#' @examples
	#' x = c("1.6", "1.6.0")
	#' compareVersion(x[1], x[2])
	#' x2 = make_full_version(x)
	#' compareVersion(x2[1], x2[2])
	#' x = c("1.6", "1.6.0")
	#' compareVersion(x2[1], x2[2])
	make_full_version = function(x) {
	  nx = names(x)
	  x = as.character(x)
	  r <- lapply(strsplit(x, "[.-]"), as.integer)
	  lx = sapply(r, length)
	  mlx = max(lx)
	  r <- lapply(r, function(ver) {
	    c(ver, rep(0, length = mlx - length(ver)))
	  })
	  x = sapply(r, paste, collapse = ".")
	  names(x) = nx
	  return(x)
	}
	
	
	
	#' Latest Neuroconductor Release Location
	#'
	#' @param secure Should https vs. http be used
	#' @param release Stable or current (development) versions
	#' @return URL of release page
	#' @export
	#'
	#' @examples
	#' make_release_version("2018/02/", check = FALSE)
	#' \donttest{
	#' latest_neuroc_release()
	#' }
	latest_neuroc_release = function(secure = TRUE) {
	  make_release_version(
	    release_path = NULL,
	    secure = secure)
	}
	
	#' @rdname latest_neuroc_release
	#' @export
	binary_release_repo = function(
	  release = c("stable", "current"),
	  secure = TRUE) {
	  release = match.arg(release)
	  release_version = paste0("latest/", release, "/")
	  release_version = make_release_version(release_version, secure = secure)
	  return(release_version)
	}
	
	#' @rdname latest_neuroc_release
	#' @param release_path path to the release on
	#' \url{https://neuroconductor.org/releases/}
	#' @param check should the `release_path` need to be checked against
	#' all the releases?
	#' @export
	make_release_version = function(release_path = NULL, secure = TRUE,
	                                check = TRUE) {
	  if (is.null(release_path)) {
	    check = TRUE
	  }
	  if (check) {
	    df = release_versions()
	
	    if (is.null(release_path)) {
	      release_path = df$release[1]
	    }
	    if (!all(release_path %in% df$release)) {
	      warning(paste0("Release path created, but not in the ",
	                     "Neuroconductor set of releases"))
	    }
	  }
	  release_path = paste0(
	    "http", ifelse(secure, "s", ""), "://neuroconductor.org/releases/",
	    release_path)
	  release_path
	}
	
	
	
	#' @rdname latest_neuroc_release
	#' @importFrom utils download.file
	#' @export
	release_versions = function(secure = TRUE) {
	  # read from the page Adi Makes
	  # currently fail
	  url = paste0("http", ifelse(secure, "s", ""),
	               "://neuroconductor.org/api/releases/")
	  destfile = tempfile(fileext = ".txt")
	  x = try({
	    download.file(url = url, destfile = destfile, quiet = TRUE)
	  }, silent = TRUE)
	  if (inherits(x, "try-error") || x != 0) {
	    warning(paste0(
	      "Releases did not download, may be error with downloading ",
	      url))
	    if (requireNamespace("httr", quietly = TRUE)) {
	      url = sub("https", "http", url)
	      res = httr::GET(url,
	                      httr::write_disk(path = destfile, overwrite = TRUE),
	                      config = httr::config(ssl_verifypeer = FALSE))
	      httr::warn_for_status(res)
	    }
	  }
	  releases = readLines(destfile, warn = FALSE)
	  releases = trimws(releases)
	  releases = gsub('"', "", releases)
	  releases = releases[grepl("releases/", releases)]
	  releases = gsub('"', "", releases)
	  releases = trimws(releases)
	  releases = sub(',$', "", releases)
	
	  releases = sub("^releases/", "", releases)
	  ss = t(sapply(strsplit(releases, "/"), rbind))
	  colnames(ss) = c("year", "month")
	  df = data.frame(release = releases, stringsAsFactors = FALSE)
	  df = cbind(df, ss, stringsAsFactors = FALSE)
	  df = df[ df$year != "latest", , drop = FALSE]
	  df$year = as.numeric(df$year)
	  df$date = paste0(df$year, "-", df$month, "-01")
	  df$date = as.Date(x = df$date, format = "%Y-%m-%d")
	  df = df[ order(df$date, decreasing = TRUE), , drop = FALSE]
	  return(df)
	}

	#' @title Neuroconductor Package Table
	#' @description Returns the table of Neuroconductor packages
	#' @return \code{data.frame} of packages with commit IDs
	#' @param path Path to the table of package
	#' @param long Should the data be "long" (with respect to stable/current)
	#' @param deployment indicator if this is a release, not standard flag.
	#' @export
	#'
	#' @note Package information is obtained from
	#' \url{https://neuroconductor.org/neurocPackages}
	#'
	#' @importFrom stats reshape
	#' @examples
	#' neuro_package_table()
	neuro_package_table = function(
	  path = "https://neuroconductor.org/neurocPackages",
	  long = FALSE,
	  deployment = FALSE
	) {
	  #############################
	  ## grab list of current neuroc packages
	  #############################
	  args = list(file = path,
	              stringsAsFactors = FALSE, header = TRUE,
	              na.strings = ifelse(deployment, "NA", ""))
	  suppressWarnings({
	    tab = try( {
	      do.call("read.csv", args)
	    } , silent = TRUE)
	  })
	  if (inherits(tab, "try-error")) {
	    args$file = gsub("^https", "http", args$file)
	    suppressWarnings({
	      tab = try( {
	        do.call("read.csv", args)
	      } , silent = TRUE)
	    })
	    if (inherits(tab, "try-error")) {
	      if (requireNamespace("httr", quietly = TRUE)) {
	        destfile = tempfile()
	        httr::GET(args$file,
	                  httr::write_disk(path = destfile),
	                  config = httr::config(ssl_verifypeer = FALSE))
	        args$file = destfile
	        tab = do.call("read.csv", args)
	      }
	    }
	  }
	
	  if (nrow(tab) == 0) {
	    return(NULL)
	  }
	  xcn = colnames(tab) = c("repo",
	                          "version.stable",
	                          "neuroc_version.stable",
	                          "commit_id.stable",
	                          "version.current",
	                          "neuroc_version.current",
	                          "commit_id.current")
	  bad_version = is.na(tab$version.stable) | tab$version.stable %in% ""
	  tab$v = "0.0.0"
	  tab$v[!bad_version] = package_version(tab$version.stable[!bad_version])
	  if (nrow(tab) == 0 & !long) {
	    return(tab)
	  }
	  ss = split(tab, tab$repo)
	  ss = lapply(ss, function(x) {
	    x = x[ order(x$v, decreasing = TRUE), ]
	    x = x[1,,drop = FALSE]
	    x$v = NULL
	    x
	  })
	  tab = do.call("rbind", ss)
	  tab = as.data.frame(tab, stringsAsFactors = FALSE)
	
	  rownames(tab) = NULL
	  if (long) {
	    cn = colnames(tab)
	    varying = cn[ cn != "repo"]
	    if (nrow(tab) == 0) {
	      cn = sapply(strsplit(xcn, "[.]"), function(x) x[1])
	      cn = unique(cn)
	      tab = matrix(NA, nrow = 0, ncol = length(cn))
	      tab = data.frame(tab)
	      colnames(tab) = cn
	    } else {
	      tab = reshape(
	        data = tab, direction = "long",
	        idvar = "repo", varying = varying,
	        times = c("current", "stable"), timevar = "release")
	    }
	    rownames(tab) = NULL
	  }
	  return(tab)
	}
	
	
	
	#' @title Neuroconductor Packages
	#' @description Returns the vector of Neuroconductor packages
	#' @return \code{vector} of packages available on Neuroconductor
	#' @param ... Arguments passed to \code{\link{neuro_package_table}}
	#'
	#' @export
	#'
	#' @examples
	#' neuro_packages()
	neuro_packages = function(...) {
	  tab = neuro_package_table(...)
	  tab = tab$repo
	  tab = unique(tab)
	  return(tab)
	}
# } else {
#   require("neurocInstall")
#   pkgs = devtools::session_info()
#   pkgs = pkgs$packages
#   pkg_ver = pkgs$version[ pkgs$package %in% "neurocInstall"]
#   message(paste0("Using neurocInstall version: ", pkg_ver,
#           ", using neurocInstall::neurocLite for installation.")
#   )
# }
