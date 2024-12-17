# Test with safe code
echo "const apiUrl = 'https://api.example.com'" > safe.js
git add safe.js
git commit -m "Add safe code"
# Should pass

# Test with unsafe code (API key)
echo "const apiKey = 'abcd1234efgh5678ijkl9012mnop3456'" > unsafe.js
git add unsafe.js
git commit -m "Add unsafe code"
# Should fail

# Test with password
echo "const password = 'mysecretpassword123'" > config.js
git add config.js
git commit -m "Add config"
# Should fail

# Test with AWS credentials
echo "AWS_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE'" > aws.js
git add aws.js
git commit -m "Add AWS config"
# Should fail
