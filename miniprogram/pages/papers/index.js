const { request } = require('../../utils/request')

Page({
  data: {
    categories: [
      { label: '全部', value: 'all' },
      { label: '急危重症', value: 'critical_care' },
      { label: '肺移植', value: 'lung_transplant' }
    ],
    currentCategory: 'all',
    currentJournalId: null,
    journals: [],
    allJournals: [],
    journalNameMap: {},
    papers: [],
    loading: false
  },

  onShow() {
    this.loadAll()
  },

  onPullDownRefresh() {
    this.loadAll().finally(() => wx.stopPullDownRefresh())
  },

  async loadAll() {
    await this.loadJournals()
    await this.loadPapers()
  },

  async loadJournals() {
    try {
      const allJournals = await request('/journals')
      const filtered = this.data.currentCategory === 'all'
        ? allJournals
        : allJournals.filter(journal => journal.category === this.data.currentCategory)
      const journalNameMap = {}
      allJournals.forEach(journal => { journalNameMap[journal.id] = journal.name })
      this.setData({ allJournals, journals: filtered, journalNameMap })
    } catch (err) {
      wx.showToast({ title: '期刊加载失败', icon: 'none' })
    }
  },

  async loadPapers() {
    this.setData({ loading: true })
    try {
      const data = {
        limit: 50,
        offset: 0
      }
      if (this.data.currentJournalId) {
        data.journal_id = this.data.currentJournalId
      }
      const res = await request('/papers', { data })
      this.setData({ papers: res.items || [] })
    } catch (err) {
      wx.showToast({ title: '文献加载失败', icon: 'none' })
    } finally {
      this.setData({ loading: false })
    }
  },

  switchCategory(event) {
    const currentCategory = event.currentTarget.dataset.value
    const journals = currentCategory === 'all'
      ? this.data.allJournals
      : this.data.allJournals.filter(journal => journal.category === currentCategory)
    this.setData({ currentCategory, journals, currentJournalId: null })
    this.loadPapers()
  },

  switchJournal(event) {
    this.setData({ currentJournalId: Number(event.currentTarget.dataset.id) })
    this.loadPapers()
  },

  clearJournal() {
    this.setData({ currentJournalId: null })
    this.loadPapers()
  },

  openDetail(event) {
    wx.navigateTo({
      url: `/pages/papers/detail?id=${event.currentTarget.dataset.id}`
    })
  }
})
