describe Sinatra::Application do
  before do
    cleanup_routes
  end
  
  after do
    cleanup_routes
  end
  
  it "should report a 500 error" do
    app.set :intercept_internal_errors, true
    
    app.get('/spec/failure') { asdfsadf }
    
    rc = api_call get '/spec/failure'
    rc.should fail(500, 'Internal error')
    
    rc = api_call get '/spec/failure'
    rc.should fail(500, 'Internal error')    
    
    app.set :intercept_internal_errors, false
  end
   
  it "should report a 404 error" do
    rc = api_call get '/spec/failure'
    rc.should fail(404, 'No such resource')
  end
  
  it "should report a 404 resource error" do
    app.get('/spec/:space_id/failure', requires: [ :space ]) {
      halt 200
    }
    
    rc = api_call get '/spec/123/failure'
    rc.should fail(404, 'No such resource: Space#123')
  end
  
  
  it "should report a 401 error" do
    app.get('/spec/failure', auth: :user) { halt 200 }
    rc = api_call get '/spec/failure'
    rc.should fail(401, 'You must sign in first')
  end
    
end