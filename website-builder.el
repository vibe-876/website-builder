;; -*- lexical-binding: t; -*-
(require 'ox-publish)


(setq top-html "<!DOCTYPE html><head><title>Blog</title><link rel=\"stylesheet\" href=\"styles.css\"><body><h1>Blog Entries</h1><a href=\"index.html\">Back Home</a><p>Please note that these are not in the order they were posted -- I'm currently working on that. There is an <a href=\"rss.xml\">RSS feed</a>, which is mostly working, but for now, you'll need to read on the site itself.<ul>"
      bottom-html "</ul></body>"
      top-rss "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><rss version=\"2.0\"><channel>"
      link-rss "https://vibe-876.github.io"
      bottom-rss "</channel></rss>")


(defun cam/build-website (rss-directories)
  "RSS-DIRECTORIES are the directories that will have
their org files put into the RSS feed."
  (interactive "D")
  (cam/build-website-directory)
  (cam/generate-rss-feed (directory)))

(defun cam/build-website-posts-page (post-directory)
  "Constructs a HTML page that lists all blog entries, in the order
that they were written."
  (let ((posts (directory-files post-directory t "\\.html$"))
	(old-buffer (current-buffer))
	(posts-file-name "blog.html"))
    
    (set-buffer (get-buffer-create posts-file-name))
    (delete-region (point-min) (point-max))
    (insert top-html)
    (mapcar (lambda (file-name)
	      (insert (concat "<li><a href=\"posts/" (file-name-nondirectory file-name) "\">"
			      ;; Stupid hack, fix me later.
			      (cam/remove-org-plist-data-from-text
			       (org-publish-find-property (file-name-with-extension file-name ".org")
							  :title nil))
			      "</a></li>")))
	    posts)
    (insert bottom-html)
    (write-file posts-file-name)
    (set-buffer old-buffer)))

(defun cam/build-website-directory (start-dir)
  "Builds all pages, including adding a link to all
other pages. START-DIR is the root directory of the
website."
  (let* ((org-files (directory-files-recursively "." (rx (one-or-more anychar)
							".org"
							line-end)))
	 (org-directories (delete-dups
			   (mapcar #'file-name-directory org-files))))
    (mapcar #'cam/build-website-page  org-files)))

(defun cam/build-website-page (org-file)
  "Builds an individual page. ORG-FILE is the org
file that is to be translated to html. In future versions,
this may also take a plist as an argument, for the
org export settings."
  (let ((org-html-head "")
	(org-html-head-extra "")
	(org-html-head-include-default-style nil)
	(org-html-head-include-scripts nil)
	(org-html-preamble nil)
	(org-html-postamble nil)
	(org-html-use-infojs nil))
    (with-temp-buffer
      (if (insert-file-contents org-file)
	  (org-html-export-to-html)))))

(defun cam/remove-org-plist-data-from-text (plist-string)
  "Stripts formatting from a plist string."
  (let ((plist-text (car plist-string)))
    (set-text-properties 0 (length plist-text)
			 nil plist-text)
    plist-text))

(defun cam/generate-rss (post-directory)
  "Generates an RSS feed, based on the Org files in POSTS-DIRECTORY.
This will use the title and date set in the Org file's tags."
  (message "WARNING: THIS DOESN'T WORK YET!!")
  (let ((org-files (directory-files post-directory t "\\.org$"))
	(old-buffer (current-buffer))
	(rss-file-name "rss.xml"))
    
    (set-buffer (get-buffer-create rss-file-name))
    (delete-region (point-min) (point-max))
    (insert top-rss)
    (mapcar (lambda (file-name)
	      (insert (concat "<entry><title>"
			      (cam/remove-org-plist-data-from-text 
			       (org-publish-find-property file-name :title nil))
			      "</title><link>" link-rss "/" post-directory "/"
			      (file-name-nondirectory
			       (file-name-with-extension file-name ".html"))
			      "</link><description>>:3</description><content type=\"html\">"
			      (shell-command-to-string (concat "pandoc -t html " file-name))
			      "</content></entry>")))
	    org-files)
    (insert bottom-rss)
    (write-file rss-file-name)
    (set-buffer old-buffer)))


(provide 'website-builder)
