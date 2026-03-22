"""
    html_audit(site_root; strict=false, skip_prefixes=String[])

Audit generated HTML files for common issues. Checks every `.html` file
under `site_root` for:

- Missing or empty `<title>` tag
- Missing `<meta name="description">` (attribute order independent)
- Missing `<link rel="canonical">` (skipped for `404.html`)
- More than one `<h1>` element
- Images with empty `alt=""` attributes
- Images missing the `alt` attribute entirely

Returns a `Vector{String}` of issue descriptions (empty if no issues found).
When `strict=true`, throws an error instead of returning the issues vector.
Files under any path in `skip_prefixes` are excluded from the audit.
"""
function html_audit(
        site_root::String;
        strict::Bool = false,
        skip_prefixes::Vector{String} = String[]
    )::Vector{String}
    issues = String[]

    for (root, _, files) in walkdir(site_root)
        for file in files
            endswith(file, ".html") || continue
            fpath = joinpath(root, file)
            rel = relpath(fpath, site_root)
            rel = replace(rel, '\\' => '/')
            any(startswith(rel, p) for p in skip_prefixes) && continue

            html = read(fpath, String)

            # <title> must exist and be non-empty
            if !occursin(r"<title>.+?</title>"s, html)
                push!(issues, "$rel: missing or empty <title>")
            end

            # meta description (handle both attribute orders)
            has_desc = occursin(r"<meta\b[^>]*\bname=[\"']description[\"'][^>]*\bcontent=[\"'][^\"']+[\"']"s, html) ||
                       occursin(r"<meta\b[^>]*\bcontent=[\"'][^\"']+[\"'][^>]*\bname=[\"']description[\"']"s, html)
            if !has_desc
                push!(issues, "$rel: missing meta description")
            end

            # canonical link (not required on 404)
            if rel != "404.html" &&
               !occursin(r"<link\s+rel=[\"']canonical[\"']"s, html)
                push!(issues, "$rel: missing canonical link")
            end

            # single <h1>
            h1_count = sum(1 for _ in eachmatch(r"<h1\b"s, html); init=0)
            if h1_count != 1
                push!(issues, "$rel: expected 1 <h1>, found $h1_count")
            end

            # no empty alt text
            empty_alt = sum(1 for _ in eachmatch(r"<img\b[^>]*\balt=[\"'][\"']"s, html); init=0)
            if empty_alt > 0
                push!(issues, "$rel: $empty_alt image(s) with empty alt text")
            end

            # images missing alt attribute entirely (more serious than empty alt)
            no_alt = sum(1 for _ in eachmatch(r"<img\b(?![^>]*\balt\b)[^>]*>"s, html); init=0)
            if no_alt > 0
                push!(issues, "$rel: $no_alt image(s) missing alt attribute")
            end
        end
    end

    if isempty(issues)
        return String[]
    end

    msg = "HTML audit found $(length(issues)) issue(s):\n" *
          join(("  • " * iss for iss in issues), "\n")

    if strict
        error(msg)
    else
        print_warning(msg)
        return issues
    end
end
