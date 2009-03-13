#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "rexml/document"
require "rexml/xpath"
require "openssl"
require "xmlcanonicalizer"
require "digest/sha1"

class SamlResponse 

  def self.login_success(username, request, public_key, private_key)
    issueTimeStamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    validTillTimeStamp = Time.now.since(10.minutes).utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    # generating login assertion
    xml_string = ''
    xml = Builder::XmlMarkup.new(:target => xml_string)
    xml.instruct!
    xml.samlp(:Response, 'xmlns:samlp' => "urn:oasis:names:tc:SAML:2.0:protocol",
      'xmlns' => "urn:oasis:names:tc:SAML:2.0:assertion",
      'xmlns:xenc' => "http://www.w3.org/2001/04/xmlenc#",
      'ID' => randomId,
      'IssueInstant' => issueTimeStamp,
      'Version' => "2.0") { 
      xml.samlp(:Status) { xml.samlp(:StatusCode, 'Value' => "urn:oasis:names:tc:SAML:2.0:status:Success")}
      xml.Assertion('ID' => randomId,
        'Version' => "2.0",
        'IssueInstant' => issueTimeStamp,
        'xmlns' => "urn:oasis:names:tc:SAML:2.0:assertion") {
        xml.Issuer('https://www.opensaml.org/IDP')
        xml.Subject {
          xml.NameID(username, 'Format' => "urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress")
          xml.SubjectConfirmation('Method' => "urn:oasis:names:tc:SAML:2.0:cm:bearer")
        }
        xml.Conditions('NotBefore' => request.root.attributes["IssueInstant"], 'NotOnOrAfter' => validTillTimeStamp)
        xml.AuthnStatement('AuthnInstant' => issueTimeStamp) {
          xml.AuthnContext {
            xml.AuthnContextClassRef('urn:oasis:names:tc:SAML:2.0:ac:classes:Password')
          }
        }
      }
    }
    doc = REXML::Document.new(xml_string)
    # generating signature 
    xml_string = ''
    xml = Builder::XmlMarkup.new(:target => xml_string)
    xml.Signature('xmlns' => "http://www.w3.org/2000/09/xmldsig#") {
      xml.SignedInfo {
        xml.CanonicalizationMethod('Algorithm' => "http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments")
        xml.SignatureMethod('Algorithm' => "http://www.w3.org/2000/09/xmldsig#rsa-sha1")
        xml.Reference(URI => "") {
          xml.Transforms {
            xml.Transform('Algorithm' => "http://www.w3.org/2000/09/xmldsig#enveloped-signature")
          }
          xml.DigestMethod('Algorithm' => "http://www.w3.org/2000/09/xmldsig#sha1")
          xml.DigestValue('TBD')
        }
      }
      xml.SignatureValue('TBD')
      xml.KeyInfo {
        xml.KeyValue {
          xml.RSAKeyValue {
            xml.Modulus(Base64.encode64(public_key.n.to_s(2)))
            xml.Exponent(Base64.encode64(public_key.e.to_s(2)))
          }
        }
      }
    }
    # forming digests and signatures
    signature = REXML::Document.new(xml_string)
    canonicalizer = XML::Util::XmlCanonicalizer.new(false, true)
    # XML::Util::XmlCanonicalizer v.1.0.1 does not correctly support multiple namespaces, so this manual correction is needed
    assertion = canonicalizer.canonicalize(doc).chomp.
      gsub('xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns="urn:oasis:names:tc:SAML:2.0:assertion"', 'xmlns="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#"')
    signature.elements["//Signature/SignedInfo/Reference/DigestValue"].text = Base64.encode64(Digest::SHA1.digest(assertion)).chomp
    canonicalizer = XML::Util::XmlCanonicalizer.new(false, true)
    # XML::Util::XmlCanonicalizer v.1.0.1 does not correctly support multiple namespaces, so this manual correction is needed
    signed_info = canonicalizer.canonicalize(signature.elements["//Signature/SignedInfo"]).chomp.
      gsub('<SignedInfo>', '<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">')
    signature.elements["//Signature/SignatureValue"].text = Base64.encode64(private_key.sign(OpenSSL::Digest::SHA1.new, signed_info)).chomp
    # transplating signature into original document
    doc.root.insert_before(doc.elements["//samlp:Status"], signature.root)
    doc.to_s
  end
  
  private
  def self.randomId
    # 160 pseodo-random bits
    array = ('a'..'z').to_a + ('A'..'Z').to_a
    (1..20).collect{|u| array[rand(array.size)]}.join
  end

end
