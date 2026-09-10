/// A Modal tree shared by VM rendering tests, browser interaction tests, and
/// the stylesheet coverage guard.
List<Map<String, dynamic>> modalFixtureComponents() => [
  {'id': 'root', 'component': 'Modal', 'trigger': 'open', 'content': 'content'},
  {
    'id': 'open',
    'component': 'Button',
    'child': 'open-label',
    'action': {
      'event': {'name': 'opened'},
    },
  },
  {'id': 'open-label', 'component': 'Text', 'text': 'Open details'},
  {'id': 'content', 'component': 'Text', 'text': 'Hidden details'},
];

/// A Tabs tree shared by VM rendering tests, browser interaction tests, and
/// the stylesheet coverage guard.
List<Map<String, dynamic>> tabsFixtureComponents({
  Object firstTitle = 'First',
}) => [
  {
    'id': 'root',
    'component': 'Tabs',
    'tabs': [
      {'title': firstTitle, 'child': 'first'},
      {'title': 'Second', 'child': 'second'},
    ],
  },
  {'id': 'first', 'component': 'Text', 'text': 'First panel'},
  {'id': 'second', 'component': 'Text', 'text': 'Second panel'},
];
