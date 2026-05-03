(require 'ox-publish)


(setq top-html "<!DOCTYPE html><head><title>Blog</title><link rel=\"stylesheet\" href=\"styles.css\"><body><h1>Blog Entries</h1><a href=\"index.html\">Back Home</a><p>Please note that these are not in the order they were posted -- I'm currently working on that. There is an <a href=\"rss.xml\">RSS feed</a>, which is mostly working, but for now, you'll need to read on the site itself.<ul>"
      bottom-html "</ul></body>"
      top-rss "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><rss version=\"2.0\"><channel>"
      link-rss "https://vibe-876.github.io"
      bottom-rss "</channel></rss>")


(defun cam/build-website ()
  (interactive)
  (cam/build-website-directory "." "styles.css")
  (cam/build-website-directory "posts" "../styles.css")
  (cam/build-website-posts-page "posts")
  (cam/generate-rss "posts"))

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

(defun cam/remove-org-plist-data-from-text (plist-string)
  "Stripts formatting from a plist string."
  (let ((plist-text (car plist-string)))
    (set-text-properties 0 (length plist-text)
			 nil plist-text)
    plist-text))

(defun cam/build-website-directory (directory css-file)
  "Converts all Org files to HTML, using pandoc. DIRECTORY is
the directory containing the files to be converted, and CSS-FILE
is the file containing the CSS they should be using."
  (let ((org-source-files (directory-files directory t "\\.org$")))
    (mapcar 'cam/build-page org-source-files)))

(defun cam/build-page (file-name)
  "Builds an individual page from an Org file, using
pandoc."
  (shell-command (concat "pandoc "
			 file-name
			 " -o "
			 (file-name-with-extension file-name ".html")
			 " --css=\"" css-file "\" -s "
			 "--syntax-highlighting=\"espresso\"")))

(defun cam/generate-rss (post-directory)
  "Generates an RSS feed, based on the Org files in POSTS-DIRECTORY.
This will use the title and date set in the Org file's tags."
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
