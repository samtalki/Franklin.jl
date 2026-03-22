@testset "html_audit" begin
    good_html = """
        <html><head>
        <title>Test Page</title>
        <meta name="description" content="A test page">
        <link rel="canonical" href="https://example.com/test/">
        </head><body>
        <h1>Hello</h1>
        <img src="test.png" alt="A test image">
        </body></html>
    """

    @testset "passes valid HTML" begin
        dir = mktempdir()
        write(joinpath(dir, "good.html"), good_html)
        @test isempty(F.html_audit(dir))
    end

    @testset "catches missing title" begin
        dir = mktempdir()
        write(joinpath(dir, "bad.html"), """
            <html><head>
            <meta name="description" content="Test">
            <link rel="canonical" href="https://example.com/">
            </head><body><h1>Hello</h1></body></html>
        """)
        @test !isempty(F.html_audit(dir))
    end

    @testset "catches duplicate h1" begin
        dir = mktempdir()
        write(joinpath(dir, "bad.html"), """
            <html><head>
            <title>Test</title>
            <meta name="description" content="Test">
            <link rel="canonical" href="https://example.com/">
            </head><body><h1>One</h1><h1>Two</h1></body></html>
        """)
        @test !isempty(F.html_audit(dir))
    end

    @testset "catches empty alt text" begin
        dir = mktempdir()
        write(joinpath(dir, "bad.html"), """
            <html><head>
            <title>Test</title>
            <meta name="description" content="Test">
            <link rel="canonical" href="https://example.com/">
            </head><body><h1>Hello</h1>
            <img src="test.png" alt="">
            </body></html>
        """)
        @test !isempty(F.html_audit(dir))
    end

    @testset "strict mode throws" begin
        dir = mktempdir()
        write(joinpath(dir, "bad.html"), """
            <html><head></head><body><h1>X</h1></body></html>
        """)
        @test_throws ErrorException F.html_audit(dir; strict=true)
    end

    @testset "skip_prefixes" begin
        dir = mktempdir()
        mkpath(joinpath(dir, "docs"))
        write(joinpath(dir, "good.html"), good_html)
        write(joinpath(dir, "docs", "bad.html"), "<html></html>")
        @test isempty(F.html_audit(dir; skip_prefixes=["docs"]))
    end

    @testset "404 skips canonical check" begin
        dir = mktempdir()
        write(joinpath(dir, "404.html"), """
            <html><head>
            <title>404</title>
            <meta name="description" content="Not found">
            </head><body><h1>Not Found</h1></body></html>
        """)
        @test isempty(F.html_audit(dir))
    end

    @testset "catches zero h1" begin
        dir = mktempdir()
        write(joinpath(dir, "noh1.html"), """
            <html><head><title>Test</title>
            <meta name="description" content="Test">
            <link rel="canonical" href="https://example.com/">
            </head><body><p>No heading</p></body></html>
        """)
        @test !isempty(F.html_audit(dir))
    end

    @testset "catches missing alt attribute" begin
        dir = mktempdir()
        write(joinpath(dir, "noalt.html"), """
            <html><head><title>Test</title>
            <meta name="description" content="Test">
            <link rel="canonical" href="https://example.com/">
            </head><body><h1>Hello</h1>
            <img src="test.png">
            </body></html>
        """)
        @test !isempty(F.html_audit(dir))
    end

    @testset "handles reversed meta description attribute order" begin
        dir = mktempdir()
        write(joinpath(dir, "reversed.html"), """
            <html><head><title>Test</title>
            <meta content="A test page" name="description">
            <link rel="canonical" href="https://example.com/">
            </head><body><h1>Hello</h1></body></html>
        """)
        @test isempty(F.html_audit(dir))
    end
end
