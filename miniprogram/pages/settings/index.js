const app = getApp()
const { getBaseURL } = require('../../utils/request')

Page({
  data: {
    apiBaseURL: ''
  },

  onShow() {
    this.setData({ apiBaseURL: getBaseURL() })
  },

  onInput(event) {
    this.setData({ apiBaseURL: event.detail.value })
  },

  save() {
    const value = this.data.apiBaseURL.trim()
    if (!/^https?:\/\/.+/.test(value)) {
      wx.showToast({ title: '请输入 http/https 地址', icon: 'none' })
      return
    }
    wx.setStorageSync('apiBaseURL', value)
    app.globalData.apiBaseURL = value
    wx.showToast({ title: '已保存' })
  }
})
