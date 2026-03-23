@testset "SEO hfuns" begin
    @testset "seo_canonical_url" begin
        set_globals()
        F.set_var!(F.GLOBAL_VARS, "website_url", "https://example.com")

        # Regular page
        F.set_var!(F.LOCAL_VARS, "fd_url", "/blog/post/index.html")
        @test F.hfun_seo_canonical_url() == "https://example.com/blog/post/"
        @test !occursin("index.html", F.hfun_seo_canonical_url())

        # Homepage
        F.set_var!(F.LOCAL_VARS, "fd_url", "/index.html")
        @test F.hfun_seo_canonical_url() == "https://example.com/"

        # Already normalized URL
        F.set_var!(F.LOCAL_VARS, "fd_url", "/about/")
        @test F.hfun_seo_canonical_url() == "https://example.com/about/"

        # Trailing slash on website_url
        F.set_var!(F.GLOBAL_VARS, "website_url", "https://example.com/")
        F.set_var!(F.LOCAL_VARS, "fd_url", "/blog/post/index.html")
        @test F.hfun_seo_canonical_url() == "https://example.com/blog/post/"

        # Empty website_url returns empty
        F.set_var!(F.GLOBAL_VARS, "website_url", "")
        @test F.hfun_seo_canonical_url() == ""
    end

    @testset "seo_canonical_url with prepath" begin
        set_globals()
        F.set_var!(F.GLOBAL_VARS, "website_url", "https://user.github.io")
        F.set_var!(F.GLOBAL_VARS, "prepath", "myrepo")
        F.FD_ENV[:FINAL_PASS] = true

        F.set_var!(F.LOCAL_VARS, "fd_url", "/blog/post/index.html")
        result = F.hfun_seo_canonical_url()
        @test occursin("myrepo", result)
        @test !occursin("index.html", result)

        # Reset
        F.FD_ENV[:FINAL_PASS] = false
    end

    @testset "seo_page_title" begin
        set_globals()
        F.set_var!(F.GLOBAL_VARS, "website_title", "My Site")

        # Regular page
        F.set_var!(F.LOCAL_VARS, "title", "Blog Post")
        @test F.hfun_seo_page_title() == "Blog Post | My Site"

        # Homepage (title == site name)
        F.set_var!(F.LOCAL_VARS, "title", "My Site")
        @test F.hfun_seo_page_title() == "My Site"

        # Empty title
        F.set_var!(F.LOCAL_VARS, "title", "")
        @test F.hfun_seo_page_title() == "My Site"
    end

    @testset "seo_og_type" begin
        set_globals()

        # Homepage
        set_curpath("index.md")
        @test F.hfun_seo_og_type() == "website"

        # Content page
        set_curpath("blog/post.md")
        @test F.hfun_seo_og_type() == "article"

        # Paper page
        set_curpath("papers/2025/paper.md")
        @test F.hfun_seo_og_type() == "article"
    end

    @testset "seo_last_modified" begin
        set_globals()

        # Homepage returns empty
        set_curpath("index.md")
        @test F.hfun_seo_last_modified() == ""

        # 404 returns empty
        set_curpath("404.md")
        @test F.hfun_seo_last_modified() == ""
    end
end
