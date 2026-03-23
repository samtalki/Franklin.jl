#=
Built-in hfuns for SEO: canonical URLs, page titles, Open Graph types,
and last-modified dates. Use in templates as {{seo_canonical_url}}, etc.

These use the `seo_` prefix to avoid collisions with user-defined hfuns.
Users can override any of these by defining their own `hfun_seo_*` in
utils.jl (user-defined hfuns take precedence per Franklin's dispatch).
=#

"""
$(SIGNATURES)

Return the canonical URL for the current page. Combines `website_url` with
the current page path, stripping `index.html` for directory-style URLs.
Handles `prepath` for sites deployed at subpaths (e.g., GitHub Pages
project sites). Returns empty string if `website_url` is not configured.

Usage in templates: `{{seo_canonical_url}}`
"""
function hfun_seo_canonical_url()::String
    base = rstrip(globvar(:website_url)::String, '/')
    isempty(base) && return ""
    url  = locvar(:fd_url)::String
    # Handle prepath for subpath deploys (e.g., user.github.io/repo/)
    pp = globvar(:prepath)::String
    if !isempty(pp) && FD_ENV[:FINAL_PASS]::Bool
        if !startswith(url, "/$pp")
            url = "/$pp" * url
        end
    end
    # Normalize: strip index.html suffix
    url = replace(url, r"/index\.html$" => "/")
    url = base * url
    # Escape for safe use in HTML attributes
    url = replace(url, "&" => "&amp;", "\"" => "&quot;", "'" => "&#39;",
                       "<" => "&lt;", ">" => "&gt;")
    return url
end


"""
$(SIGNATURES)

Return a formatted page title: "Page Title | Site Name".
Returns just the site name for the homepage or when the page title
matches the site name.

The separator defaults to " | " and can be overridden by setting
`title_separator` in config.md.

Usage in templates: `{{seo_page_title}}`
"""
function hfun_seo_page_title()::String
    site = globvar(:website_title)::String
    title = locvar(:title)
    if title isa AbstractString
        t = strip(String(title))
        if !isempty(t) && t != site
            sep = let s = globvar(:title_separator)
                s isa AbstractString && !isempty(s) ? String(s) : " | "
            end
            return t * sep * site
        end
    end
    return site
end


"""
$(SIGNATURES)

Return the Open Graph type for the current page: "article" for content
pages, "website" for index and tag pages.

Usage in templates: `{{seo_og_type}}`
"""
function hfun_seo_og_type()::String
    rpath = locvar(:fd_rpath)
    s = isnothing(rpath) ? "" : String(rpath)
    if isempty(s) || s == "index" || s == "index.md" ||
       startswith(s, "tag/")
        return "website"
    end
    return "article"
end


"""
$(SIGNATURES)

Return the last-modified date of the current page as a string, or an
empty string for the homepage and 404 page.

Usage in templates: `{{seo_last_modified}}`
"""
function hfun_seo_last_modified()::String
    rpath = locvar(:fd_rpath)
    if rpath !== nothing
        p = String(rpath)
        (p in ("index", "index.md", "404", "404.md")) && return ""
    end
    mtime = locvar(:fd_mtime)
    if mtime isa AbstractString
        stripped = strip(mtime)
        if !isempty(stripped) && !startswith(stripped, "0001")
            return stripped
        end
    end
    return ""
end
