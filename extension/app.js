// Apna App State & Controllers

const DEFAULT_DOCUMENTS = [
  { id: '1', title: 'Home Insurance Policy.pdf', category: 'insurance', size: '2.4 MB', date: 'Today', icon: '🛡️' },
  { id: '2', title: 'Passport - Shubham.pdf', category: 'kyc', size: '1.1 MB', date: 'Yesterday', icon: '🪪' },
  { id: '3', title: 'Laptop Warranty.pdf', category: 'warranty', size: '2.4 MB', date: '3 days ago', icon: '💻' },
  { id: '4', title: 'Car RC.jpg', category: 'vehicle', size: '3.2 MB', date: '3 days ago', icon: '🚗' },
  { id: '5', title: 'Aadhaar Card - Shubham.pdf', category: 'kyc', size: '850 KB', date: '5 days ago', icon: '🆔' }
];

let currentWorkspace = localStorage.getItem('apna_workspace') || 'Family';
let documents = JSON.parse(localStorage.getItem('apna_documents')) || DEFAULT_DOCUMENTS;

// Initialize on Load
document.addEventListener('DOMContentLoaded', () => {
  checkIndiaLegalConsent();
  updateWorkspaceUI();
  renderDashboardDocs();
  renderDocumentsList();
  setupNavigation();
  setupConsentEvents();
});

// India Legal Consent Gatekeeper
function checkIndiaLegalConsent() {
  const consentRecord = localStorage.getItem('apna_dpdp_consent');
  if (!consentRecord) {
    document.getElementById('consentModal').style.display = 'flex';
  }
}

function setupConsentEvents() {
  const chkTerms = document.getElementById('chkTerms');
  const btnAccept = document.getElementById('btnAcceptConsent');

  chkTerms?.addEventListener('change', () => {
    btnAccept.disabled = !chkTerms.checked;
  });
}

function acceptConsent() {
  const consentData = {
    userId: 'user-default-shubham',
    termsVersion: 'v1.0.0-2026',
    privacyVersion: 'v1.0.0-2026',
    consentedAt: new Date().toISOString(),
    purposes: {
      kycVault: document.getElementById('chkKyc').checked,
      billTracking: document.getElementById('chkBills').checked,
      offlineSync: document.getElementById('chkSync').checked
    },
    jurisdiction: 'India (DPDP Act 2023)'
  };

  localStorage.setItem('apna_dpdp_consent', JSON.stringify(consentData));
  document.getElementById('consentModal').style.display = 'none';
  showToast('Consent recorded in DPDP statutory audit ledger.');
}

// Workspace Switcher
document.getElementById('wsToggle')?.addEventListener('click', () => {
  currentWorkspace = currentWorkspace === 'Family' ? 'Personal' : 'Family';
  localStorage.setItem('apna_workspace', currentWorkspace);
  updateWorkspaceUI();
  showToast(`Switched to ${currentWorkspace} workspace`);
});

function updateWorkspaceUI() {
  document.getElementById('wsName').textContent = currentWorkspace;
  document.getElementById('greetingWs').textContent = currentWorkspace;
}

// Navigation Tabs
function setupNavigation() {
  document.querySelectorAll('.nav-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const view = tab.getAttribute('data-view');
      switchView(view, tab.textContent);
    });
  });
}

function switchTab(viewName) {
  document.querySelectorAll('.nav-tab').forEach(t => {
    if (t.getAttribute('data-view') === viewName) {
      t.click();
    }
  });
}

function switchView(viewName, title) {
  document.querySelectorAll('.view-panel').forEach(p => p.style.display = 'none');

  if (viewName === 'dashboard') {
    document.getElementById('view-dashboard').style.display = 'block';
  } else if (viewName === 'documents') {
    document.getElementById('view-documents').style.display = 'block';
  } else {
    const generic = document.getElementById('view-generic');
    generic.style.display = 'block';
    document.getElementById('genericTitle').textContent = title || viewName;
  }
}

// Render Documents
function renderDashboardDocs() {
  const container = document.getElementById('dashboardRecentDocs');
  if (!container) return;
  container.innerHTML = documents.slice(0, 4).map(doc => `
    <div class="item-row">
      <div class="item-info">
        <div class="item-icon">${doc.icon || '📄'}</div>
        <div class="item-text">
          <h4>${doc.title}</h4>
          <p>${doc.category.toUpperCase()} • ${doc.size} • ${doc.date}</p>
        </div>
      </div>
      <span style="font-size:12px; color:var(--text-muted); cursor:pointer;" onclick="shareDoc('${doc.title}')">↗</span>
    </div>
  `).join('');
}

function renderDocumentsList(filterCat = null) {
  const container = document.getElementById('documentsList');
  if (!container) return;

  const filtered = filterCat 
    ? documents.filter(d => d.category === filterCat)
    : documents;

  container.innerHTML = filtered.map(doc => `
    <div class="item-row">
      <div class="item-info">
        <div class="item-icon">${doc.icon || '📄'}</div>
        <div class="item-text">
          <h4>${doc.title}</h4>
          <p>${doc.category.toUpperCase()} • ${doc.size} • ${doc.date}</p>
        </div>
      </div>
      <div style="display:flex; gap:8px;">
        <button class="upi-btn" style="background:#eff6ff; color:var(--blue); border-color:#dbeafe;" onclick="shareDoc('${doc.title}')">Share</button>
        <button class="upi-btn" style="background:#fef2f2; color:var(--error); border-color:#fee2e2;" onclick="deleteDoc('${doc.id}')">Delete</button>
      </div>
    </div>
  `).join('');
}

function filterCategory(cat) {
  renderDocumentsList(cat);
  showToast(`Filtering by ${cat.toUpperCase()}`);
}

// Document Actions
function openAddDocModal() {
  document.getElementById('addDocModal').style.display = 'flex';
}

function closeAddDocModal() {
  document.getElementById('addDocModal').style.display = 'none';
}

function saveDocument(e) {
  e.preventDefault();
  const title = document.getElementById('docTitle').value.trim();
  const category = document.getElementById('docCategory').value;
  const docNumber = document.getElementById('docNumber').value.trim();

  const newDoc = {
    id: Date.now().toString(),
    title: title.endsWith('.pdf') || title.endsWith('.jpg') ? title : `${title}.pdf`,
    category: category,
    size: '1.2 MB',
    date: 'Just now',
    icon: category === 'kyc' ? '🪪' : category === 'insurance' ? '🛡️' : '📄'
  };

  documents.unshift(newDoc);
  localStorage.setItem('apna_documents', JSON.stringify(documents));

  renderDashboardDocs();
  renderDocumentsList();
  closeAddDocModal();
  document.getElementById('addDocForm').reset();
  showToast(`Document "${newDoc.title}" encrypted and saved to offline vault`);
}

function deleteDoc(id) {
  documents = documents.filter(d => d.id !== id);
  localStorage.setItem('apna_documents', JSON.stringify(documents));
  renderDashboardDocs();
  renderDocumentsList();
  showToast('Document removed from local vault');
}

function shareDoc(title) {
  showToast(`Generating secure temporary link for ${title}`);
}

// UPI Intent Launcher
function launchUPI(title, amount, vpa) {
  const upiUrl = `upi://pay?pa=${encodeURIComponent(vpa)}&pn=${encodeURIComponent(title)}&am=${amount}&cu=INR&tn=${encodeURIComponent('Apna Bill - ' + title)}`;
  
  // Try opening native protocol
  window.open(upiUrl, '_blank');
  showToast(`Initiating UPI payment for ${title} (₹${amount}) via ${vpa}`);
}

function triggerAction(actionName) {
  showToast(`Triggered: ${actionName}`);
}

// Toast notification helper
function showToast(msg) {
  const existing = document.getElementById('apna-toast');
  if (existing) existing.remove();

  const toast = document.createElement('div');
  toast.id = 'apna-toast';
  toast.textContent = msg;
  toast.style.cssText = `
    position: fixed;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: #0f172a;
    color: #fff;
    padding: 10px 18px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
    z-index: 200;
    box-shadow: 0 4px 14px rgba(0,0,0,0.25);
    animation: fadeIn 0.2s ease;
  `;

  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 2800);
}
