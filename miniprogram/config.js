const DEV_API_BASE_URL = 'https://flask-6fvj-255873-7-1430464465.sh.run.tcloudbase.com'
const PROD_API_BASE_URL = 'https://flask-6fvj-255873-7-1430464465.sh.run.tcloudbase.com'

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
