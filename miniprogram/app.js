const { getDefaultAPIBaseURL } = require('./config')

function isLocalDevelopmentURL(url) {
  return /^http:\/\/(localhost|127\.0\.0\.1|10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)/.test(url || '')
}

App({
  globalData: {
    apiBaseURL: ''
  },

  onLaunch() {
    const defaultURL = getDefaultAPIBaseURL()
    const savedURL = wx.getStorageSync('apiBaseURL')
    const shouldReset = !savedURL || defaultURL.startsWith('https://') && isLocalDevelopmentURL(savedURL)
    const apiBaseURL = shouldReset ? defaultURL : savedURL
    wx.setStorageSync('apiBaseURL', apiBaseURL)
    this.globalData.apiBaseURL = apiBaseURL
  }
})
