const app = getApp()
const { DEV_API_BASE_URL, getDefaultAPIBaseURL } = require('../config')

function getBaseURL() {
  return app.globalData.apiBaseURL || wx.getStorageSync('apiBaseURL') || getDefaultAPIBaseURL()
}

function fallbackURLs(primary) {
  const preferred = getDefaultAPIBaseURL()
  const urls = [preferred, primary, DEV_API_BASE_URL, 'http://127.0.0.1:8000', 'http://localhost:8000']
  return urls.filter((url, index) => url && urls.indexOf(url) === index)
}

function request(path, options = {}) {
  const method = options.method || 'GET'
  const data = options.data || {}
  const urls = fallbackURLs(getBaseURL())

  return new Promise((resolve, reject) => {
    let cursor = 0

    const tryNext = lastError => {
      if (cursor >= urls.length) {
        reject(lastError || new Error('request failed'))
        return
      }
      const baseURL = urls[cursor]
      cursor += 1

    wx.request({
      url: `${baseURL}${path}`,
      method,
      data,
      header: {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      },
      success(res) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          wx.setStorageSync('apiBaseURL', baseURL)
          app.globalData.apiBaseURL = baseURL
          resolve(res.data)
          return
        }
        tryNext(new Error(`HTTP ${res.statusCode}`))
      },
      fail(err) {
        tryNext(err)
      }
    })
    }

    tryNext()
  })
}

function formatDate(date) {
  const d = date instanceof Date ? date : new Date(date)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

module.exports = {
  request,
  getBaseURL,
  formatDate
}
