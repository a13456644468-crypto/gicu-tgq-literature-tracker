const { request, formatDate } = require('../../utils/request')

function blankPatient(date, shift) {
  return {
    localId: `${Date.now()}-${Math.random()}`,
    checklist_date: date,
    shift,
    bed_number: '',
    patient_name: '',
    diagnosis: '',
    pathogen: '',
    antibiotics: '',
    anticoagulation: '',
    nutrition: '',
    planned_io: '',
    actual_io: '',
    notes: ''
  }
}

Page({
  data: {
    date: formatDate(new Date()),
    shift: 'day',
    patients: []
  },

  onLoad() {
    this.setData({ patients: [blankPatient(this.data.date, this.data.shift)] })
  },

  onDateChange(event) {
    const date = event.detail.value
    const patients = this.data.patients.map(item => ({ ...item, checklist_date: date }))
    this.setData({ date, patients })
  },

  setShift(event) {
    const shift = event.currentTarget.dataset.shift
    const patients = this.data.patients.map(item => ({ ...item, shift }))
    this.setData({ shift, patients })
  },

  addPatient() {
    this.setData({
      patients: this.data.patients.concat(blankPatient(this.data.date, this.data.shift))
    })
  },

  removePatient(event) {
    const index = Number(event.currentTarget.dataset.index)
    const patients = this.data.patients.filter((_, i) => i !== index)
    this.setData({
      patients: patients.length ? patients : [blankPatient(this.data.date, this.data.shift)]
    })
  },

  onInput(event) {
    const { index, field } = event.currentTarget.dataset
    const patients = this.data.patients.slice()
    patients[index][field] = event.detail.value
    this.setData({ patients })
  },

  async loadChecklist() {
    try {
      const items = await request('/checklists', {
        data: {
          checklist_date: this.data.date,
          shift: this.data.shift
        }
      })
      const patients = items.length
        ? items.map(item => ({ ...item, localId: `server-${item.id}` }))
        : [blankPatient(this.data.date, this.data.shift)]
      this.setData({ patients })
    } catch (err) {
      wx.showToast({ title: '加载失败', icon: 'none' })
    }
  },

  validatePatients() {
    const valid = this.data.patients.filter(item => (
      item.bed_number.trim() &&
      item.patient_name.trim() &&
      item.diagnosis.trim()
    ))
    if (!valid.length) {
      wx.showToast({ title: '请填写床号、姓名、诊断', icon: 'none' })
      return null
    }
    return valid.map(({ localId, id, created_at, updated_at, ...item }) => ({
      ...item,
      checklist_date: this.data.date,
      shift: this.data.shift
    }))
  },

  async saveChecklist() {
    const payload = this.validatePatients()
    if (!payload) return
    wx.showLoading({ title: '保存中' })
    try {
      const items = await request('/checklists/batch', {
        method: 'POST',
        data: payload
      })
      this.setData({
        patients: items.map(item => ({ ...item, localId: `server-${item.id}` }))
      })
      wx.showToast({ title: '已保存' })
    } catch (err) {
      wx.showToast({ title: '保存失败', icon: 'none' })
    } finally {
      wx.hideLoading()
    }
  },

  async exportJPG() {
    const payload = this.validatePatients()
    if (!payload) return
    wx.showLoading({ title: '生成图片' })
    try {
      const filePath = await this.drawChecklist(payload)
      await this.saveImage(filePath)
      wx.showToast({ title: '已保存相册' })
    } catch (err) {
      wx.showToast({ title: '导出失败', icon: 'none' })
    } finally {
      wx.hideLoading()
    }
  },

  drawChecklist(items) {
    return new Promise((resolve, reject) => {
      const query = wx.createSelectorQuery()
      query.select('#exportCanvas').fields({ node: true, size: true }).exec(res => {
        const canvas = res && res[0] && res[0].node
        if (!canvas) {
          reject(new Error('canvas unavailable'))
          return
        }
        const width = 1400
        const rowHeight = 96
        const headerHeight = 150
        const height = headerHeight + rowHeight * (items.length + 1) + 60
        const dpr = wx.getSystemInfoSync().pixelRatio || 2
        canvas.width = width * dpr
        canvas.height = height * dpr
        const ctx = canvas.getContext('2d')
        ctx.scale(dpr, dpr)
        this.drawTable(ctx, width, height, items)
        wx.canvasToTempFilePath({
          canvas,
          fileType: 'jpg',
          quality: 1,
          success: temp => resolve(temp.tempFilePath),
          fail: reject
        })
      })
    })
  },

  drawTable(ctx, width, height, items) {
    const headers = ['床号', '姓名', '诊断', '病原体', '抗生素', '抗凝', '营养', '计划出入量', '实际出入量', '备注']
    const fields = ['bed_number', 'patient_name', 'diagnosis', 'pathogen', 'antibiotics', 'anticoagulation', 'nutrition', 'planned_io', 'actual_io', 'notes']
    const colWidths = [86, 110, 170, 140, 160, 110, 110, 130, 130, 164]
    const startX = 40
    const startY = 150
    const rowHeight = 96

    ctx.fillStyle = '#ffffff'
    ctx.fillRect(0, 0, width, height)
    ctx.fillStyle = '#0f172a'
    ctx.font = 'bold 34px sans-serif'
    ctx.fillText('浙江大学医学院附属第二医院 GICU', 40, 55)
    ctx.font = 'bold 46px sans-serif'
    ctx.fillText('ICU 每日 Checklist', 40, 112)
    ctx.font = '28px sans-serif'
    ctx.fillText(`${this.data.date}  ${this.data.shift === 'day' ? '白班' : '夜班'}`, 1080, 92)

    let x = startX
    headers.forEach((header, index) => {
      this.drawCell(ctx, x, startY, colWidths[index], rowHeight, header, true)
      x += colWidths[index]
    })

    items.forEach((item, rowIndex) => {
      x = startX
      fields.forEach((field, colIndex) => {
        this.drawCell(ctx, x, startY + rowHeight * (rowIndex + 1), colWidths[colIndex], rowHeight, item[field] || '', false)
        x += colWidths[colIndex]
      })
    })
  },

  drawCell(ctx, x, y, width, height, text, isHeader) {
    ctx.fillStyle = isHeader ? '#ccfbf1' : '#ffffff'
    ctx.fillRect(x, y, width, height)
    ctx.strokeStyle = '#64748b'
    ctx.lineWidth = 1
    ctx.strokeRect(x, y, width, height)
    ctx.fillStyle = '#0f172a'
    ctx.font = isHeader ? 'bold 22px sans-serif' : '20px sans-serif'
    this.wrapText(ctx, String(text), x + 8, y + 30, width - 16, 26, 3)
  },

  wrapText(ctx, text, x, y, maxWidth, lineHeight, maxLines) {
    let line = ''
    let lineCount = 0
    for (let i = 0; i < text.length; i++) {
      const testLine = line + text[i]
      if (ctx.measureText(testLine).width > maxWidth && line) {
        ctx.fillText(line, x, y + lineCount * lineHeight)
        line = text[i]
        lineCount += 1
        if (lineCount >= maxLines) return
      } else {
        line = testLine
      }
    }
    if (line && lineCount < maxLines) {
      ctx.fillText(line, x, y + lineCount * lineHeight)
    }
  },

  saveImage(filePath) {
    return new Promise((resolve, reject) => {
      wx.saveImageToPhotosAlbum({
        filePath,
        success: resolve,
        fail: reject
      })
    })
  }
})
