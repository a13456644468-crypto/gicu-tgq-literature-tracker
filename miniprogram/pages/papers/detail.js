const { request } = require('../../utils/request')

Page({
  data: {
    paper: null,
    journalName: '未知期刊'
  },

  async onLoad(options) {
    const id = Number(options.id)
    if (!id) return
    await this.loadPaper(id)
  },

  async loadPaper(id) {
    try {
      const paper = await request(`/papers/${id}`)
      const journals = await request('/journals')
      const journal = journals.find(item => item.id === paper.journal_id)
      this.setData({ paper, journalName: journal ? journal.name : '未知期刊' })
    } catch (err) {
      wx.showToast({ title: '详情加载失败', icon: 'none' })
    }
  },

  copyPubMed() {
    if (!this.data.paper || !this.data.paper.pubmed_url) return
    wx.setClipboardData({ data: this.data.paper.pubmed_url })
  },

  async markRead() {
    if (!this.data.paper) return
    try {
      const paper = await request(`/papers/${this.data.paper.id}/read`, { method: 'POST' })
      this.setData({ paper })
      wx.showToast({ title: '已标记' })
    } catch (err) {
      wx.showToast({ title: '操作失败', icon: 'none' })
    }
  }
})
