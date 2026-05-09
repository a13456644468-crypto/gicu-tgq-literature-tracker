const DEV_API_BASE_URL = 'http://10.196.43.135:8000'

// Replace this with your public HTTPS backend domain before publishing.
const PROD_API_BASE_URL = 'https://api.yourdomain.com'

function getDefaultAPIBaseURL() {
  const account = wx.getAccountInfoSync ? wx.getAccountInfoSync() : null
  const envVersion = account && account.miniProgram ? account.miniProgram.envVersion : 'develop'
  return envVersion === 'release' ? PROD_API_BASE_URL : DEV_API_BASE_URL
}

module.exports = {
  DEV_API_BASE_URL,
  PROD_API_BASE_URL,
  getDefaultAPIBaseURL
}
