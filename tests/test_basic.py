def test_import():
    try:
        from src.job_posting import crew
        assert True
    except ImportError:
        assert False, "Failed to import crew module"
